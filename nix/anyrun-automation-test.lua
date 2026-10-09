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

-- Run argv against a fresh log and the given queued selections.
local function pick(argv, selection)
    reset()
    write_file(selections, selection or "")
    return run(argv)
end

-- Wait for a detached process to reach the command log.
local function wait_for_log(pattern)
    for _ = 1, 40 do
        if read_file(command_log):find(pattern) then
            return true
        end
        process.run({assert(os.getenv("sleepCommand")), "0.05"})
    end
    return false
end

-- Worker actions run their commands.
assert(pick({actions, "--worker", "lock"}) == 0)
assert(read_file(command_log):find("swaylock\n%-f\n"))

-- Screenshots are written and copied.
assert(pick({actions, "--worker", "screenshot-full"}) == 0)
assert(read_file(clipboard_output) == "\137PNG\0fixture")
assert(stat.stat(root .. "/2026-08-30_12-00-00.png"))

-- Clipboard history decodes the selected entry.
assert(pick({clipboard}, "1\tfixture\n") == 0)
assert(read_file(clipboard_output) == "decoded\0clipboard")

-- Emoji picker copies the glyph of the selected row.
local emoji_data = read_file(assert(os.getenv("emojiData")))
local first_line = emoji_data:match("^([^\n]*)")
assert(pick({emoji}, first_line .. "\n") == 0)
assert(read_file(clipboard_output) == first_line:match("^(%S+)"))

-- Wi-Fi: page one shows the actions, then the connected network and the
-- strongest access points, merged per SSID and with signal and security.
assert(pick({wifi}) == 0)
local menu = read_file(menu_input)
local connected_at = assert(menu:find("reprisabe  ▂▄  WPA3 (connected)", 1, true))
local home_at = assert(menu:find("HomeWifi  ▂▄▆  WPA2", 1, true))
local open_at = assert(menu:find("OpenWifi  ▂▄▆  open", 1, true))
assert(connected_at < home_at and home_at < open_at, "networks are not sorted")
assert(not menu:find("HomeWifi", home_at + 1, true), "duplicate SSIDs are not merged")
assert(menu:find("Rescan networks", 1, true) < connected_at, "actions are not listed before the networks")
assert(menu:find("Disconnect from reprisabe", 1, true))
assert(menu:find("Show Wi-Fi password / QR", 1, true))
assert(menu:find("Forget a saved network", 1, true))
assert(menu:find("Turn Wi-Fi off", 1, true))
assert(menu:find("Turn networking off", 1, true))
assert(menu:find("Open network settings", 1, true))
assert(menu:find("Next page ▸", 1, true))
assert(not menu:find("SavedNet (saved)", 1, true), "overflow items leaked onto page one")

-- Wi-Fi: page two carries the overflow items and a way back.
assert(pick({wifi}, "Next page ▸\n") == 0)
local second_page = read_file(menu_input)
assert(second_page:find("◂ Previous page", 1, true))
assert(second_page:find("Extra08", 1, true))
assert(second_page:find("SavedNet (saved)", 1, true))
assert(not second_page:find("reprisabe", 1, true), "page two repeats page one items")
assert(not second_page:find("Rescan networks", 1, true), "actions are not reserved for page one")

-- Wi-Fi: paging back returns to the first page.
assert(pick({wifi}, "Next page ▸\n◂ Previous page\n") == 0)
assert(read_file(menu_input):find("Rescan networks", 1, true))

-- Wi-Fi: open network connects directly.
assert(pick({wifi}, "OpenWifi  ▂▄▆  open\n") == 0)
assert(read_file(command_log):find("nmcli\ndevice\nwifi\nconnect\nOpenWifi\n", 1, true))

-- Wi-Fi: secured network opens the interactive nmcli in a terminal.
assert(pick({wifi}, "HomeWifi  ▂▄▆  WPA2\n") == 0)
assert(wait_for_log("foot\n%-e\n.-%-%-ask\ndevice\nwifi\nconnect\nHomeWifi\n"), "foot did not open for a secured network")

-- Wi-Fi: saved connection is brought up by UUID.
assert(pick({wifi}, "Next page ▸\nSavedNet (saved)\n") == 0)
assert(read_file(command_log):find("nmcli\nconnection\nup\nuuid\n11111111-2222-3333-4444-555555555555\n", 1, true))

-- Wi-Fi: disconnect brings the active connection down.
assert(pick({wifi}, "Disconnect from reprisabe\n") == 0)
assert(read_file(command_log):find("nmcli\nconnection\ndown\nuuid\nd6c23df2-be6a-4cca-8eb1-f595a47fb1fc\n", 1, true))

-- Wi-Fi: forgetting a saved network needs confirmation.
assert(pick({wifi}, "Forget a saved network\nSavedNet (saved)\nCancel\n") == 0)
assert(not read_file(command_log):find("connection\ndelete", 1, true))
assert(pick({wifi}, "Forget a saved network\nSavedNet (saved)\nForget SavedNet (saved)\n") == 0)
assert(read_file(command_log):find("nmcli\nconnection\ndelete\nuuid\n11111111-2222-3333-4444-555555555555\n", 1, true))

-- Wi-Fi: rescan reopens the menu with a blocking rescan.
assert(pick({wifi}, "Rescan networks\n") == 0)
assert(read_file(command_log):find("list\n--rescan\nyes\n", 1, true))

-- Wi-Fi: the password viewer holds a terminal open.
assert(pick({wifi}, "Show Wi-Fi password / QR\n") == 0)
assert(wait_for_log("foot\n%-%-hold\n%-e\n.-device\nwifi\nshow%-password\n"), "foot did not open for the password")

-- Wi-Fi: radio and networking toggles call nmcli.
assert(pick({wifi}, "Turn Wi-Fi off\n") == 0)
assert(read_file(command_log):find("nmcli\nradio\nwifi\noff\n", 1, true))
assert(pick({wifi}, "Turn networking off\n") == 0)
assert(read_file(command_log):find("nmcli\nnetworking\noff\n", 1, true))

local output = assert(io.open(assert(os.getenv("out")), "wb"))
assert(output:write("ok\n"))
assert(output:close())
