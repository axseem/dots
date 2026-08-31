local process = require("axseem.process")
local bit = require("bit")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")

local sink_path = assert(os.getenv("TMPDIR")) .. "/lua-automation-sink"

local function write_file(path, value)
    local file = assert(io.open(path, "wb"))
    assert(file:write(value))
    assert(file:close())
end

local function read_file(path)
    local file = assert(io.open(path, "rb"))
    local value = assert(file:read("*a"))
    file:close()
    return value
end

if arg[1] == "sink" then
    write_file(sink_path, io.stdin:read("*a"))
    os.exit(0)
elseif arg[1] == "exec" then
    process.exec({ assert(os.getenv("printfCommand")), "%s", "replaced" })
end

local function command(name)
    local value = assert(os.getenv(name), "missing test command: " .. name)
    return value
end

assert(process.run({ command("trueCommand") }) == 0)
assert(process.run({ command("falseCommand") }, { stdout = "discard", stderr = "discard" }) == 1)

local result = process.capture({
    command("printfCommand"),
    "%s|%s|%s|%s|%s",
    "space separated",
    "quote'\"",
    "*",
    "-leading",
    "",
})
assert(result.code == 0)
assert(result.out == "space separated|quote'\"|*|-leading|")

local input = string.rep("x\0", 500000)
result = process.capture({ command("catCommand") }, input)
assert(result.code == 0)
assert(result.out == input)

result = process.capture({ command("falseCommand") }, nil, { stderr = "discard" })
assert(result.code == 1)

assert(process.feed({ command("luaCommand"), arg[0], "sink" }, input) == 0)
assert(read_file(sink_path) == input)

result = process.capture({ command("luaCommand"), arg[0], "exec" })
assert(result.code == 0)
assert(result.out == "replaced")

for _, variable in ipairs({
    "actionsScript",
    "bluetoothScript",
    "formatterScript",
    "lsnixScript",
    "mimeScript",
    "secretScript",
    "swayidleScript",
}) do
    assert(loadfile(assert(os.getenv(variable), variable .. " is not set")))
end

local original_path = assert(os.getenv("PATH"))
result = process.capture(
    { command("luaCommand"), assert(os.getenv("lsnixScript")) },
    nil,
    { stderr = "discard" }
)
assert(result.code == 1)
assert(stdlib.setenv("IN_NIX_SHELL", "pure", true))
assert(stdlib.setenv("buildInputs", "/nix/store/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-alpha-1 /nix/store/bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb-beta-2", true))
assert(stdlib.setenv("nativeBuildInputs", "/nix/store/cccccccccccccccccccccccccccccccc-alpha-1", true))
assert(stdlib.setenv("propagatedBuildInputs", "not-a-store-path", true))
result = process.capture({ command("luaCommand"), assert(os.getenv("lsnixScript")) })
assert(result.code == 0)
assert(result.out == "alpha-1\nbeta-2\n")
assert(stdlib.setenv("PATH", original_path, true))

local root = assert(os.getenv("TMPDIR")) .. "/managed-automation"
assert(stat.mkdir(root, tonumber("700", 8)))
local formatter_log = root .. "/formatter-log"
local alejandra = root .. "/alejandra.lua"
write_file(alejandra, [[#!/usr/bin/env lua
local file = assert(io.open(assert(os.getenv("formatterLog")), "wb"))
for index = 1, #arg do assert(file:write(arg[index], "\n")) end
assert(file:close())
]])
assert(stat.chmod(alejandra, tonumber("700", 8)))
assert(stdlib.setenv("formatterLog", formatter_log, true))
assert(stdlib.setenv("ALEJANDRA", alejandra, true))
assert(stdlib.setenv("PATH", assert(os.getenv("runtimeBin")), true))
assert(process.run({ command("luaCommand"), assert(os.getenv("formatterScript")) }) == 0)
assert(read_file(formatter_log) == "--quiet\n.\n")

local mime_types = root .. "/mime-types"
local mime_log = root .. "/mime-log"
local xdg_mime = root .. "/xdg-mime.lua"
write_file(mime_types, "text/plain\nimage/png\ntext/markdown\n")
write_file(mime_log, "")
write_file(xdg_mime, [[#!/usr/bin/env lua
local file = assert(io.open(assert(os.getenv("mimeLog")), "ab"))
for index = 1, #arg do assert(file:write(arg[index], "\n")) end
assert(file:close())
]])
assert(stat.chmod(xdg_mime, tonumber("700", 8)))
assert(stdlib.setenv("mimeLog", mime_log, true))
assert(stdlib.setenv("PATH", assert(os.getenv("runtimeBin")), true))
assert(process.run({
    command("luaCommand"),
    assert(os.getenv("mimeScript")),
    mime_types,
    "nvim.desktop",
    xdg_mime,
}) == 0)
assert(read_file(mime_log) == "default\nnvim.desktop\ntext/plain\ndefault\nnvim.desktop\ntext/markdown\n")

local secret_path = root .. "/secret"
assert(process.run({ command("luaCommand"), assert(os.getenv("secretScript")), secret_path }) == 0)
local secret = read_file(secret_path)
assert(secret:match("^SEARX_SECRET_KEY=%x+\n$"))
assert(#secret == 82)
assert(bit.band(assert(stat.stat(secret_path)).st_mode, tonumber("777", 8)) == tonumber("600", 8))
assert(process.run({ command("luaCommand"), assert(os.getenv("secretScript")), secret_path }) == 0)
assert(read_file(secret_path) == secret)

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
