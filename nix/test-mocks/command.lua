#!/usr/bin/env lua

-- Mock for the external commands the menu scripts call, plus the anyrun
-- picker. Invoked through PATH symlinks named after the command, so arg[0]
-- selects the behaviour.
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

local function has(argv, wanted)
    for _, value in ipairs(argv) do
        if value == wanted then
            return true
        end
    end
    return false
end

-- Picker mock: consumes the menu on stdin, records it when MENU_INPUT is
-- set, then prints the next queued selection (or MOCK_INPUT/MOCK_SELECTION).
local function anyrun()
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
end

local name = basename(arg[0])
local argv = {}
for index = 1, #arg do
    argv[#argv + 1] = arg[index]
end

if name == "anyrun" then
    anyrun()
elseif name == "bluetoothctl" or name == "swaylock" then
    append_log(name, argv)
elseif name == "mkdir" then
    -- no-op in tests
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
elseif name == "nmcli" then
    if has(argv, "radio") then
        io.stdout:write("WIFI:enabled\n")
    elseif has(argv, "list") then
        io.stdout:write(":OpenWifi:\n:HomeWifi:WPA2\n")
    elseif has(argv, "show") then
        io.stdout:write("SavedNet:802-11-wireless\nWired:802-3-ethernet\n")
    else
        append_log(name, argv)
    end
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
