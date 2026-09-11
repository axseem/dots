local process = require("axseem.process")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")

local helpers = dofile(assert(os.getenv("testHelpers")))
local write_file = helpers.write_file
local read_file = helpers.read_file

if arg[1] == "spawn" then
    write_file(assert(arg[2]), "spawned\n")
    os.exit(0)
end

local root = assert(os.getenv("TMPDIR")) .. "/fuzzel-automation"
assert(stat.mkdir(root, tonumber("700", 8)))
local command_log = root .. "/command-log"
local clipboard_output = root .. "/clipboard-output"
local menu_input = root .. "/menu-input"
local selections = root .. "/selections"
local data_home = root .. "/data"
local detached = root .. "/detached"

assert(stdlib.setenv("PATH", assert(os.getenv("commandBin")) .. ":" .. assert(os.getenv("runtimeBin")), true))
assert(stdlib.setenv("COMMAND_LOG", command_log, true))
assert(stdlib.setenv("CLIPBOARD_OUTPUT", clipboard_output, true))
assert(stdlib.setenv("MENU_INPUT", menu_input, true))
assert(stdlib.setenv("MOCK_SELECTIONS", selections, true))
assert(stdlib.setenv("HOME", root, true))
assert(stdlib.setenv("SCREENSHOT_DIR", root, true))
assert(stdlib.setenv("XDG_DATA_HOME", data_home, true))
assert(stdlib.setenv("XDG_DATA_DIRS", root .. "/empty", true))
assert(stdlib.setenv("XDG_CURRENT_DESKTOP", "Hyprland", true))

local actions = assert(os.getenv("actionsApp"))
local launcher = assert(os.getenv("launcherApp"))
local calc = assert(os.getenv("calcApp"))
local clipboard = assert(os.getenv("clipboardApp"))
local emoji = assert(os.getenv("emojiApp"))
local bluetooth = assert(os.getenv("bluetoothApp"))
local sleep_command = assert(os.getenv("sleepCommand"))

local function reset()
    write_file(command_log, "")
    write_file(clipboard_output, "")
    write_file(menu_input, "")
    write_file(selections, "")
end

local function run(argv)
    return process.run(argv, {stderr = "discard"})
end

-- The actions menu renders every entry and dispatches the selection through
-- the detached worker.
reset()
write_file(selections, "Power off\n")
assert(run({actions}) == 0)
local log = read_file(command_log)
assert(log:find("systemd%-run\n"), "no systemd-run:\n" .. log)
assert(log:find("\n%-%-\n.-\n%-%-worker\npoweroff\n"), "bad dispatch:\n" .. log)
local menu = read_file(menu_input)
assert(menu:find("Bluetooth settings", 1, true))
assert(menu:find("Screenshot full screen", 1, true))

-- Worker actions invoke their tools.
reset()
assert(run({actions, "--worker", "wifi"}) == 0)
assert(read_file(command_log):find("networkmanager_dmenu\n$"))

-- Calculator evaluates and copies the result.
reset()
assert(stdlib.setenv("MOCK_INPUT", "8*2", true))
assert(run({calc}) == 0)
assert(read_file(clipboard_output) == "16")
assert(stdlib.setenv("MOCK_INPUT", "", true))

-- Clipboard history decodes the selected entry.
reset()
write_file(selections, "1\tfixture\n")
assert(run({clipboard}) == 0)
assert(read_file(clipboard_output) == "decoded\0clipboard")

-- Emoji picker copies the glyph of the selected row.
reset()
local emoji_data = read_file(assert(os.getenv("emojiData")))
local first_line = emoji_data:match("^([^\n]*)")
write_file(selections, first_line .. "\n")
local emoji_result = process.capture({emoji})
assert(emoji_result.code == 0, "emoji failed")
assert(read_file(clipboard_output) == first_line:match("^(%S+)"))

-- Bluetooth: pick a device, then Connect.
reset()
write_file(selections, "Headphones (paired)\nConnect\n")
assert(run({bluetooth}) == 0)
assert(read_file(command_log):find("bluetoothctl\nconnect\nAA:BB:CC:DD:EE:FF\n", 1, true))

-- The launcher shows apps and actions, and spawns the selected application.
reset()
assert(stat.mkdir(data_home, tonumber("700", 8)))
assert(stat.mkdir(data_home .. "/applications", tonumber("700", 8)))
write_file(
    data_home .. "/applications/test.desktop",
    "[Desktop Entry]\nType=Application\nName=Test App\nExec="
    .. assert(os.getenv("luaCommand"))
    .. " "
    .. arg[0]
    .. " spawn "
    .. detached
    .. "\n"
)
write_file(selections, "Test App\n")
assert(run({launcher}) == 0)
local spawned = false
for _ = 1, 40 do
    if stat.stat(detached) then
        spawned = true
        break
    end
    process.run({sleep_command, "0.1"})
end
assert(spawned, "launcher did not spawn the application")
assert(read_file(detached) == "spawned\n")
menu = read_file(menu_input)
assert(menu:find("Test App", 1, true))
assert(menu:find("Calculator", 1, true))

-- The launcher dispatches actions too.
reset()
write_file(selections, "Wi-Fi settings\n")
assert(run({launcher}) == 0)
local dispatched = false
for _ = 1, 40 do
    if read_file(command_log):find("networkmanager_dmenu") then
        dispatched = true
        break
    end
    process.run({sleep_command, "0.1"})
end
assert(dispatched, "launcher did not dispatch the action")
assert(read_file(command_log):find("networkmanager_dmenu\n$"))

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
