#!/usr/bin/env lua

-- Mock picker: consumes the menu on stdin, records it when MENU_INPUT is
-- set, then prints the next queued selection (or MOCK_INPUT/MOCK_SELECTION).
local menu = io.stdin:read("*a")
if os.getenv("MENU_INPUT") then
    local file = assert(io.open(os.getenv("MENU_INPUT"), "wb"))
    assert(file:write(menu))
    assert(file:close())
end

local queue = os.getenv("MOCK_SELECTIONS")
if queue then
    local file = io.open(queue, "rb")
    if file then
        local contents = file:read("*a")
        file:close()
        local first, rest = contents:match("^([^\n]*)\n?(.*)$")
        local remaining = assert(io.open(queue, "wb"))
        assert(remaining:write(rest or ""))
        assert(remaining:close())
        if first and first ~= "" then
            io.stdout:write(first .. "\n")
            os.exit(0)
        end
    end
end

local input = os.getenv("MOCK_INPUT")
if input and input ~= "" then
    io.stdout:write(input .. "\n")
    os.exit(0)
end

local selection = os.getenv("MOCK_SELECTION")
if selection and selection ~= "" then
    io.stdout:write(selection .. "\n")
    os.exit(0)
end

os.exit(1)
