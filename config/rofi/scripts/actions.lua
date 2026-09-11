#!/usr/bin/env lua

local process = require("axseem.process")
local rofi = require("axseem.rofi")

local trim = rofi.trim

local function write_file(path, contents)
    local file = assert(io.open(path, "wb"))
    assert(file:write(contents))
    assert(file:close())
end

local function run_detached(action)
    local argv = {
        "systemd-run",
        "--user",
        "--collect",
        "--no-block",
        "--quiet",
        "--service-type=exec",
        "--expand-environment=no",
    }
    for _, name in ipairs({
        "DISPLAY",
        "HOME",
        "HYPRLAND_INSTANCE_SIGNATURE",
        "PATH",
        "SCREENSHOT_DIR",
        "WAYLAND_DISPLAY",
        "XDG_RUNTIME_DIR",
        "XDG_SESSION_ID",
    }) do
        local value = os.getenv(name)
        if value then
            argv[#argv + 1] = "--setenv=" .. name .. "=" .. value
        end
    end
    argv[#argv + 1] = "--"
    argv[#argv + 1] = arg[0]
    argv[#argv + 1] = "--worker"
    argv[#argv + 1] = action
    return process.run(argv)
end


local function menu(input, ...)
    local argv = { "rofi", "-dmenu" }
    for _, value in ipairs({ ... }) do
        argv[#argv + 1] = value
    end
    return process.capture(argv, input, { stderr = "discard" })
end


local function confirm(label)
    local result = menu(
        "Cancel\n" .. label .. "\n",
        "-p",
        "Confirm",
        "-no-custom",
        "-no-auto-select",
        "-selected-row",
        "0"
    )
    return result.code == 0 and trim(result.out) == label
end


local function screenshot(area)
    local screenshot_directory = os.getenv("SCREENSHOT_DIR")
        or assert(os.getenv("HOME"), "HOME is not set") .. "/me/screenshots"
    local mkdir_status = process.run({ "mkdir", "-p", screenshot_directory }, { stderr = "discard" })
    if mkdir_status ~= 0 then
        return mkdir_status
    end

    local grim = { "grim" }
    if area then
        local region = process.capture({ "slurp" })
        if region.code ~= 0 then
            return region.code
        end
        grim[#grim + 1] = "-g"
        grim[#grim + 1] = trim(region.out)
    end
    grim[#grim + 1] = "-"

    local image = process.capture(grim)
    if image.code ~= 0 then
        return image.code
    end
    local timestamp = process.capture({ "date", "+%Y-%m-%d_%H-%M-%S" })
    if timestamp.code ~= 0 then
        return timestamp.code
    end

    write_file(screenshot_directory .. "/" .. trim(timestamp.out) .. ".png", image.out)
    return process.feed({ "wl-copy" }, image.out)
end


local function clipboard()
    local history = process.capture({ "cliphist", "list" })
    if history.code ~= 0 then
        return history.code
    end
    local selected = menu(history.out, "-p", "Clipboard", "-no-custom", "-no-auto-select")
    if selected.code ~= 0 then
        return selected.code
    end
    local selected_entry = selected.out:gsub("[\r\n]+$", "")
    local decoded = process.capture({ "cliphist", "decode" }, selected_entry)
    if decoded.code ~= 0 then
        return decoded.code
    end
    return process.feed({ "wl-copy" }, decoded.out)
end


local function calculator()
    local result = process.capture({ "rofi", "-show", "calc" })
    if result.code ~= 0 then
        return result.code
    end
    local value = result.out:gsub("[\r\n]+$", "")
    if value == "" then
        return 0
    end
    return process.feed({ "wl-copy" }, value)
end


local function worker(action)
    process.run({ "sleep", "0.15" }, { stderr = "discard" })

    if action == "wifi" then
        return process.run({ "networkmanager_dmenu", "-no-auto-select" })
    elseif action == "bluetooth" then
        return process.run({ "rofi", "-show", "bluetooth" })
    elseif action == "audio" then
        return process.run({ "pavucontrol" })
    elseif action == "files" then
        return process.run({ "nautilus" })
    elseif action == "emoji" then
        return process.run({ "rofi", "-show", "emoji" })
    elseif action == "clipboard" then
        return clipboard()
    elseif action == "calculator" then
        return calculator()
    elseif action == "screenshot-area" then
        return screenshot(true)
    elseif action == "screenshot-full" then
        return screenshot(false)
    elseif action == "lock" then
        return process.run({ "swaylock", "-f" })
    elseif action == "suspend" then
        return confirm("Suspend") and process.run({ "systemctl", "suspend" }) or 0
    elseif action == "logout" then
        if not confirm("Log out") then
            return 0
        end
        local session = os.getenv("XDG_SESSION_ID")
        if session and session ~= "" then
            return process.run({ "loginctl", "terminate-session", session })
        end
        if os.getenv("HYPRLAND_INSTANCE_SIGNATURE") then
            return process.run({ "hyprctl", "dispatch", "exit" })
        end
        return 1
    elseif action == "reboot" then
        return confirm("Restart") and process.run({ "systemctl", "reboot" }) or 0
    elseif action == "poweroff" then
        return confirm("Power off") and process.run({ "systemctl", "poweroff" }) or 0
    end

    io.stderr:write("unknown worker action: " .. tostring(action) .. "\n")
    return 2
end


-- Single source of truth for the action list; the selection labels map back
-- to these same actions.
local actions = {
    {label = "Wi-Fi settings", icon = "network-wireless-symbolic", action = "wifi", terms = "network internet wireless"},
    {label = "Bluetooth settings", icon = "bluetooth-symbolic", action = "bluetooth", terms = "devices connect headphones"},
    {label = "Audio settings", icon = "audio-volume-high-symbolic", action = "audio", terms = "sound volume microphone"},
    {label = "Clipboard history", icon = "edit-paste-symbolic", action = "clipboard", terms = "copy paste cliphist"},
    {label = "Calculator", icon = "accessories-calculator", action = "calculator", terms = "math arithmetic qalc"},
    {label = "Browse files", icon = "folder-symbolic", action = "files", terms = "file manager nautilus folders"},
    {label = "Emoji picker", icon = "face-smile-symbolic", action = "emoji", terms = "symbols characters"},
    {label = "Screenshot area", icon = "camera-photo-symbolic", action = "screenshot-area", terms = "capture selection snip"},
    {label = "Screenshot full screen", icon = "camera-photo-symbolic", action = "screenshot-full", terms = "capture monitor display"},
    {label = "Lock screen", icon = "system-lock-screen-symbolic", action = "lock", terms = "secure swaylock"},
    {label = "Suspend", icon = "media-playback-pause-symbolic", action = "suspend", terms = "sleep power"},
    {label = "Log out", icon = "system-log-out-symbolic", action = "logout", terms = "exit session"},
    {label = "Restart", icon = "system-reboot-symbolic", action = "reboot", terms = "reboot power"},
    {label = "Power off", icon = "system-shutdown-symbolic", action = "poweroff", terms = "shutdown turn off"},
}

local direct_actions = {}
for _, entry in ipairs(actions) do
    direct_actions[entry.label] = entry.action
end

local function print_rows()
    rofi.header()
    for _, entry in ipairs(actions) do
        rofi.row(entry.label, entry.icon, entry.action, entry.terms)
    end
end


if arg[1] == "--worker" then
    os.exit(worker(arg[2]))
end

local action = os.getenv("ROFI_INFO") or direct_actions[arg[1]]
if action then
    os.exit(run_detached(action))
elseif arg[1] == nil then
    print_rows()
    os.exit(0)
else
    io.stderr:write("unknown action: " .. arg[1] .. "\n")
    os.exit(2)
end
