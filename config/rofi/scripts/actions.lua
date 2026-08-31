#!/usr/bin/env lua

local process = require("axseem.process")

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

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


local function row(label, icon, action, terms)
    io.stdout:write(
        label .. "\0icon\x1f" .. icon .. "\x1finfo\x1f" .. action .. "\x1fmeta\x1f" .. terms .. "\n"
    )
end


local function print_rows()
    io.stdout:write("\0no-custom\x1ftrue\n")
    row("Wi-Fi settings", "network-wireless-symbolic", "wifi", "network internet wireless")
    row("Bluetooth settings", "bluetooth-symbolic", "bluetooth", "devices connect headphones")
    row("Audio settings", "audio-volume-high-symbolic", "audio", "sound volume microphone")
    row("Clipboard history", "edit-paste-symbolic", "clipboard", "copy paste cliphist")
    row("Calculator", "accessories-calculator", "calculator", "math arithmetic qalc")
    row("Browse files", "folder-symbolic", "files", "file manager nautilus folders")
    row("Emoji picker", "face-smile-symbolic", "emoji", "symbols characters")
    row("Screenshot area", "camera-photo-symbolic", "screenshot-area", "capture selection snip")
    row("Screenshot full screen", "camera-photo-symbolic", "screenshot-full", "capture monitor display")
    row("Lock screen", "system-lock-screen-symbolic", "lock", "secure swaylock")
    row("Suspend", "media-playback-pause-symbolic", "suspend", "sleep power")
    row("Log out", "system-log-out-symbolic", "logout", "exit session")
    row("Restart", "system-reboot-symbolic", "reboot", "reboot power")
    row("Power off", "system-shutdown-symbolic", "poweroff", "shutdown turn off")
end


if arg[1] == "--worker" then
    os.exit(worker(arg[2]))
end

local direct_actions = {
    ["Wi-Fi settings"] = "wifi",
    ["Bluetooth settings"] = "bluetooth",
    ["Audio settings"] = "audio",
    ["Clipboard history"] = "clipboard",
    ["Calculator"] = "calculator",
    ["Browse files"] = "files",
    ["Emoji picker"] = "emoji",
    ["Screenshot area"] = "screenshot-area",
    ["Screenshot full screen"] = "screenshot-full",
    ["Lock screen"] = "lock",
    ["Suspend"] = "suspend",
    ["Log out"] = "logout",
    ["Restart"] = "reboot",
    ["Power off"] = "poweroff",
}
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
