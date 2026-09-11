local process = require("axseem.process")
local stat = require("posix.sys.stat")
local stdlib = require("posix.stdlib")

local helpers = dofile(assert(os.getenv("testHelpers")))
local write_file = helpers.write_file
local read_file = helpers.read_file

local root = assert(os.getenv("TMPDIR")) .. "/anyrun-automation"
assert(stat.mkdir(root, tonumber("700", 8)))
local command_log = root .. "/command-log"
local clipboard_output = root .. "/clipboard-output"
local menu_input = root .. "/menu-input"
local selections = root .. "/selections"

assert(stdlib.setenv("PATH", assert(os.getenv("commandBin")) .. ":" .. assert(os.getenv("runtimeBin")), true))
assert(stdlib.setenv("COMMAND_LOG", command_log, true))
assert(stdlib.setenv("CLIPBOARD_OUTPUT", clipboard_output, true))
assert(stdlib.setenv("MENU_INPUT", menu_input, true))
assert(stdlib.setenv("MOCK_SELECTIONS", selections, true))
assert(stdlib.setenv("HOME", root, true))
assert(stdlib.setenv("SCREENSHOT_DIR", root, true))

local actions = assert(os.getenv("actionsApp"))
local clipboard = assert(os.getenv("clipboardApp"))
local emoji = assert(os.getenv("emojiApp"))
local wifi = assert(os.getenv("wifiApp"))

local function reset()
    write_file(command_log, "")
    write_file(clipboard_output, "")
    write_file(menu_input, "")
    write_file(selections, "")
end

local function run(argv)
    return process.run(argv, {stderr = "discard"})
end

-- Worker actions run their commands.
reset()
assert(run({actions, "--worker", "lock"}) == 0)
assert(read_file(command_log):find("swaylock\n%-f\n"))

-- Screenshots are written and copied.
reset()
assert(run({actions, "--worker", "screenshot-full"}) == 0)
assert(read_file(clipboard_output) == "\137PNG\0fixture")
assert(stat.stat(root .. "/2026-08-30_12-00-00.png"))

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
assert(run({emoji}) == 0)
assert(read_file(clipboard_output) == first_line:match("^(%S+)"))

-- Wi-Fi: open network connects directly.
reset()
write_file(selections, "OpenWifi (open)\n")
assert(run({wifi}) == 0)
assert(read_file(command_log):find("nmcli\ndevice\nwifi\nconnect\nOpenWifi\n", 1, true))

-- Wi-Fi: secured network opens the interactive nmcli in a terminal.
reset()
write_file(selections, "HomeWifi (WPA2)\n")
assert(run({wifi}) == 0)
local foot_logged = false
for _ = 1, 40 do
    if read_file(command_log):find("foot\n%-e\n.-%-%-ask\ndevice\nwifi\nconnect\nHomeWifi\n") then
        foot_logged = true
        break
    end
    process.run({assert(os.getenv("sleepCommand")), "0.05"})
end
assert(foot_logged, "foot did not open for a secured network")

-- Wi-Fi: saved connection is brought up by name.
reset()
write_file(selections, "SavedNet (saved)\n")
assert(run({wifi}) == 0)
assert(read_file(command_log):find("nmcli\nconnection\nup\nid\nSavedNet\n", 1, true))

-- Wi-Fi menu offers the radio toggle and the interactive fallback.
reset()
assert(run({wifi}) == 0)
local menu = read_file(menu_input)
assert(menu:find("Turn Wi-Fi off", 1, true))
assert(menu:find("Open network settings", 1, true))

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
