#!/usr/bin/env lua

local process = require("axseem.process")

local curl = "@curl@"
local jq = "@jq@"
local base_url = "http://127.0.0.1:8888/search"

local options = {
    limit = 10,
    page = 1,
    json = false,
    urls = false,
}
local query = {}
local index = 1

local function fatal(message)
    io.stderr:write(message .. "\n")
    os.exit(1)
end

local function usage()
    io.stderr:write([[
Usage: sxng [flags] <query>

Flags:
  -n int    max results (default 10)
  -c str    categories: general,news,science,it,files,social media
  -t str    time filter: d/day, w/week, m/month, y/year
  -l str    language code (default: auto)
  -e str    engines (comma-separated)
  -p int    page number (default 1)
  -json     raw JSON output
  -urls     only URLs, one per line
]])
end

local function argument(flag)
    index = index + 1
    local value = arg[index]
    if value == nil then
        fatal("Error: missing value for " .. flag)
    end
    return value
end

local function number_argument(flag)
    local value = tonumber(argument(flag))
    if value == nil then
        fatal("Error: invalid number for " .. flag)
    end
    return value
end

local function resolve_time(input)
    local valid = {
        day = "day",
        d = "day",
        ["1d"] = "day",
        week = "week",
        w = "week",
        ["1w"] = "week",
        month = "month",
        m = "month",
        ["1m"] = "month",
        year = "year",
        y = "year",
        ["1y"] = "year",
    }
    local value = valid[input:lower()]
    if value == nil then
        fatal(("Error: invalid -t value %q (expected: d/day, w/week, m/month, y/year)"):format(input))
    end
    return value
end

while index <= #arg do
    local flag = arg[index]
    if flag == "-n" then
        options.limit = number_argument(flag)
    elseif flag == "-c" then
        options.categories = argument(flag)
    elseif flag == "-t" then
        options.time_range = resolve_time(argument(flag))
    elseif flag == "-l" then
        options.language = argument(flag)
    elseif flag == "-e" then
        options.engines = argument(flag)
    elseif flag == "-p" then
        options.page = number_argument(flag)
    elseif flag == "-json" or flag == "--json" then
        options.json = true
    elseif flag == "-urls" or flag == "--urls" then
        options.urls = true
    elseif flag == "-h" or flag == "--help" then
        usage()
        os.exit(0)
    elseif flag:sub(1, 1) == "-" and flag ~= "-" then
        fatal("Error: unknown flag " .. flag)
    else
        query[#query + 1] = flag
    end
    index = index + 1
end

if #query == 0 then
    usage()
    os.exit(1)
end

local function urlencode(value)
    return (value:gsub("([^%w%-%_%.%~])", function(char)
        return string.format("%%%02X", char:byte())
    end))
end

local params = {
    {"q", table.concat(query, " ")},
    {"format", "json"},
    {"pageno", tostring(options.page)},
    {"categories", options.categories or ""},
    {"time_range", options.time_range or ""},
    {"language", options.language or ""},
    {"engines", options.engines or ""},
}
local encoded = {}
for _, param in ipairs(params) do
    if param[2] ~= "" then
        encoded[#encoded + 1] = urlencode(param[1]) .. "=" .. urlencode(param[2])
    end
end

-- Retry every second until the lazy Socket starts SearXNG, capped at 60s.
local response = process.capture({
    curl,
    "--fail",
    "--silent",
    "--show-error",
    "--retry", "60",
    "--retry-delay", "1",
    "--retry-max-time", "60",
    "--retry-connrefused",
    "--retry-all-errors",
    "--max-time", "5",
    base_url .. "?" .. table.concat(encoded, "&"),
})
if response.code ~= 0 or response.out == "" then
    fatal("Error: SearXNG not responding")
end

if options.json then
    io.stdout:write(response.out)
    return
end

local expression
if options.urls then
    expression = ".url"
else
    expression = [[("- [\(.title)](\(.url)): \(.content // "" | gsub("^\\s+|\\s+$"; ""))")]]
end
local selector = options.limit > 0 and ".results[:$n][]" or ".results[]"
local results = process.capture(
    {jq, "-r", "--argjson", "n", tostring(options.limit), selector .. " | " .. expression},
    response.out
)
if results.code ~= 0 then
    fatal("Error: failed to parse response")
end
if results.out == "" then
    io.stderr:write("No results found.\n")
    return
end
io.stdout:write(results.out)
