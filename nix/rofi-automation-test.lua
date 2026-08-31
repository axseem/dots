local process = require("axseem.process")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")

local root = assert(os.getenv("TMPDIR")) .. "/rofi-automation"
local mocks = root .. "/bin"
local command_log = root .. "/command-log"
local menu_input = root .. "/menu-input"
local clipboard_output = root .. "/clipboard-output"

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

local function append_log(name, argv)
    local file = assert(io.open(command_log, "ab"))
    assert(file:write(name .. "\n"))
    for _, value in ipairs(argv) do
        assert(file:write(value .. "\n"))
    end
    assert(file:close())
end

local function mock_command(name, argv)
    if name == "systemd-run" then
        append_log(name, argv)
    elseif name == "sleep" or name == "mkdir" then
        -- Do not delay or alter the isolated fixture directory.
    elseif name == "slurp" then
        io.stdout:write("10,20 300x400\n")
    elseif name == "date" then
        io.stdout:write("2026-08-30_12-00-00\n")
    elseif name == "grim" then
        io.stdout:write("\137PNG\0fixture")
    elseif name == "wl-copy" then
        write_file(clipboard_output, io.stdin:read("*a"))
    elseif name == "cliphist" and argv[1] == "list" then
        io.stdout:write("1\tfixture\n")
    elseif name == "cliphist" and argv[1] == "decode" then
        assert(io.stdin:read("*a") == "1\tfixture")
        io.stdout:write("decoded\0clipboard")
    elseif name == "rofi" then
        if argv[1] == "-show" then
            append_log(name, argv)
            if argv[2] == "calc" then
                io.stdout:write("42\n")
            end
        else
            write_file(menu_input, io.stdin:read("*a"))
            if os.getenv("MOCK_MENU") == "clipboard" then
                io.stdout:write("1\tfixture\n")
            else
                os.exit(1)
            end
        end
    elseif name == "busctl" then
        local operation = argv[2]
        if operation == "tree" then
            if os.getenv("MOCK_SCENARIO") == "no-adapter" then
                io.stdout:write("/org/bluez\n")
            else
                io.stdout:write("/org/bluez\n/org/bluez/hci0\n/org/bluez/hci0/dev_AA_BB_CC_DD_EE_FF\n")
            end
        elseif operation == "get-property" then
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
            error("unexpected busctl operation: " .. tostring(operation))
        end
    elseif name == "bluetoothctl" or name == "rfkill" then
        append_log(name, argv)
    else
        error("unexpected mock command: " .. name)
    end
    os.exit(0)
end

if arg[1] == "mock" then
    local argv = {}
    for index = 3, #arg do
        argv[#argv + 1] = arg[index]
    end
    mock_command(assert(arg[2]), argv)
end

assert(stat.mkdir(root, tonumber("700", 8)))
assert(stat.mkdir(mocks, tonumber("700", 8)))
write_file(command_log, "")

local mock_source = [[#!/usr/bin/env lua
local process = require("axseem.process")
local argv = { assert(os.getenv("luaCommand")), assert(os.getenv("testFile")), "mock", arg[0]:match("([^/]+)$") }
for index = 1, #arg do argv[#argv + 1] = arg[index] end
process.exec(argv)
]]
local mock_path = mocks .. "/mock.lua"
write_file(mock_path, mock_source)
assert(stat.chmod(mock_path, tonumber("700", 8)))

for _, name in ipairs({
    "bluetoothctl",
    "busctl",
    "cliphist",
    "date",
    "grim",
    "mkdir",
    "rfkill",
    "rofi",
    "sleep",
    "slurp",
    "systemd-run",
    "wl-copy",
}) do
    local path = mocks .. "/" .. name
    assert(process.run({ assert(os.getenv("lnCommand")), "-s", mock_path, path }) == 0)
end

assert(stdlib.setenv("testFile", arg[0], true))
assert(stdlib.setenv("PATH", mocks .. ":" .. assert(os.getenv("runtimeBin")), true))
assert(stdlib.setenv("HOME", root, true))
assert(stdlib.setenv("SCREENSHOT_DIR", root, true))

local scripts = assert(os.getenv("rofiScripts"))
local lua = assert(os.getenv("luaCommand"))
local actions = scripts .. "/actions.lua"
local bluetooth = scripts .. "/bluetooth.lua"

-- The actions mode preserves every original row and its search metadata.
local result = process.capture({ lua, actions })
assert(result.code == 0)
for _, expected in ipairs({
    "Wi-Fi settings",
    "Bluetooth settings",
    "Audio settings",
    "Clipboard history",
    "Calculator",
    "Browse files",
    "Emoji picker",
    "Screenshot area",
    "Screenshot full screen",
    "Lock screen",
    "Suspend",
    "Log out",
    "Restart",
    "Power off",
}) do
    assert(result.out:find(expected, 1, true))
end
assert(result.out:find("Power off\0icon\31system-shutdown-symbolic\31info\31poweroff", 1, true))

-- Selection is queued as an exact transient-service argv, not a command string.
result = process.capture({ lua, actions, "Power off" })
assert(result.code == 0)
local log = read_file(command_log)
assert(log:find("systemd%-run\n%-%-user\n%-%-collect\n%-%-no%-block\n%-%-quiet\n"))
assert(log:find("%-%-service%-type=exec\n%-%-expand%-environment=no\n"))
assert(log:find("\n%-%-\n.-\n%-%-worker\npoweroff\n"))

-- A worker can switch to the auto-discovered Bluetooth script mode directly.
write_file(command_log, "")
result = process.capture({ lua, actions, "--worker", "bluetooth" })
assert(result.code == 0)
assert(read_file(command_log):find("rofi\n%-show\nbluetooth\n"))

-- Screenshot bytes are saved and copied without a pipeline.
result = process.capture({ lua, actions, "--worker", "screenshot-area" })
assert(result.code == 0)
assert(read_file(clipboard_output) == "\137PNG\0fixture")
assert(read_file(root .. "/2026-08-30_12-00-00.png") == "\137PNG\0fixture")

-- Clipboard decode preserves binary bytes without a pipeline.
assert(stdlib.setenv("MOCK_MENU", "clipboard", true))
result = process.capture({ lua, actions, "--worker", "clipboard" })
assert(result.code == 0)
assert(read_file(clipboard_output) == "decoded\0clipboard")

-- Upstream rofi-calc prints an accepted result; the worker copies it without
-- configuring rofi-calc with a shell command.
result = process.capture({ lua, actions, "--worker", "calculator" })
assert(result.code == 0)
assert(read_file(clipboard_output) == "42")

-- Real busctl get-property output is an unlabeled typed value per invocation.
result = process.capture({ lua, bluetooth })
assert(result.code == 0)
assert(result.out:find("Headphones %(paired%)"))
assert(result.out:find("Scan for devices", 1, true))
assert(result.out:find("Turn Bluetooth off", 1, true))

-- Selecting a device transitions to actions without launching nested Rofi.
result = process.capture({ lua, bluetooth, "device\tAA:BB:CC:DD:EE:FF" })
assert(result.code == 0)
assert(result.out:find("Connect", 1, true))
assert(result.out:find("Remove pairing", 1, true))
assert(result.out:find("Untrust", 1, true))
assert(result.out:find("\0data\31AA:BB:CC:DD:EE:FF\n", 1, true))

-- A device operation reaches bluetoothctl as literal arguments.
write_file(command_log, "")
result = process.capture({ lua, bluetooth, "connect\tAA:BB:CC:DD:EE:FF" })
assert(result.code == 0)
log = read_file(command_log)
assert(log:find("bluetoothctl\nconnect\nAA:BB:CC:DD:EE:FF\n", 1, true))

-- Missing adapters produce a user-facing row and exit successfully.
assert(stdlib.setenv("MOCK_SCENARIO", "no-adapter", true))
result = process.capture({ lua, bluetooth })
assert(result.code == 0)
assert(result.out:find("No Bluetooth adapter found", 1, true))

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
