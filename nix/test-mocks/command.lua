#!/usr/bin/env lua

-- Mock for the external commands the menu scripts call. Invoked through
-- PATH symlinks named after the command, so arg[0] selects the behaviour.
local function basename(path)
    return (path:gsub(".*/", ""))
end

local function append_log(name, argv)
    local file = assert(io.open(assert(os.getenv("COMMAND_LOG")), "ab"))
    assert(file:write(name .. "\n"))
    for _, value in ipairs(argv) do
        assert(file:write(value .. "\n"))
    end
    assert(file:close())
end

local name = basename(arg[0])
local argv = {}
for index = 1, #arg do
    argv[#argv + 1] = arg[index]
end

if name == "systemd-run" or name == "networkmanager_dmenu" then
    append_log(name, argv)
elseif name == "bluetoothctl" or name == "rfkill" then
    append_log(name, argv)
elseif name == "mkdir" or name == "sleep" then
    -- no-op in tests
elseif name == "slurp" then
    io.stdout:write("10,20 300x400\n")
elseif name == "date" then
    io.stdout:write("2026-08-30_12-00-00\n")
elseif name == "grim" then
    io.stdout:write("\137PNG\0fixture")
elseif name == "wl-copy" then
    local file = assert(io.open(assert(os.getenv("CLIPBOARD_OUTPUT")), "wb"))
    assert(file:write(io.stdin:read("*a")))
    assert(file:close())
elseif name == "cliphist" then
    if argv[1] == "list" then
        io.stdout:write("1\tfixture\n")
    elseif argv[1] == "decode" then
        assert(io.stdin:read("*a") == "1\tfixture")
        io.stdout:write("decoded\0clipboard")
    else
        error("unexpected cliphist command: " .. tostring(argv[1]))
    end
elseif name == "qalc" then
    io.stdout:write(os.getenv("MOCK_RESULT") or "16", "\n")
elseif name == "busctl" then
    if argv[2] == "tree" then
        if os.getenv("MOCK_SCENARIO") == "no-adapter" then
            io.stdout:write("/org/bluez\n")
        else
            io.stdout:write("/org/bluez\n/org/bluez/hci0\n/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF\n")
        end
    elseif argv[2] == "get-property" then
        local property = argv[6]
        if property == "Alias" then
            io.stdout:write('s "Headphones"\n')
        elseif property == "Powered" or property == "Paired" or property == "Trusted" then
            io.stdout:write("b true\n")
        elseif property == "Connected" then
            io.stdout:write("b false\n")
        else
            error("unexpected BlueZ property: " .. tostring(property))
        end
    else
        error("unexpected busctl operation: " .. tostring(argv[2]))
    end
else
    error("unexpected mock command: " .. name)
end
