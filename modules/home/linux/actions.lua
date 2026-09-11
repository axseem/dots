#!/usr/bin/env lua

local process = require("axseem.process")
local picker = require("axseem.picker")
local action_data = require("axseem.actions")

local fuzzel = "@fuzzel@"
local networkmanager_dmenu = "@networkmanager_dmenu@"
local bluetooth = "@bluetooth@"
local emoji = "@emoji@"
local clipboard = "@clipboard@"
local calc = "@calc@"

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function write_file(path, contents)
    local file = assert(io.open(path, "wb"))
    assert(file:write(contents))
    assert(file:close())
end

local function rows(entries)
    local lines = {}
    for _, entry in ipairs(entries) do
        local line = entry.label
        if entry.icon then
            line = line .. "\0icon\x1f" .. entry.icon
        end
        lines[#lines + 1] = line
    end
    return table.concat(lines, "\n") .. "\n"
end

local function confirm(label)
    local selection = picker.pick(fuzzel, {
        prompt = "Confirm",
        lines = "Cancel\n" .. label .. "\n",
    })
    return selection == label
end

local function screenshot(area)
    local screenshot_directory = os.getenv("SCREENSHOT_DIR")
        or assert(os.getenv("HOME"), "HOME is not set") .. "/me/screenshots"
    if process.run({"mkdir", "-p", screenshot_directory}, {stderr = "discard"}) ~= 0 then
        return 1
    end

    local grim = {"grim"}
    if area then
        local region = process.capture({"slurp"})
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
    local timestamp = process.capture({"date", "+%Y-%m-%d_%H-%M-%S"})
    if timestamp.code ~= 0 then
        return timestamp.code
    end

    write_file(screenshot_directory .. "/" .. trim(timestamp.out) .. ".png", image.out)
    return process.feed({"wl-copy"}, image.out)
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
        "XDG_CURRENT_DESKTOP",
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

local function worker(action)
    if action == "wifi" then
        return process.exec({networkmanager_dmenu, "-no-auto-select"})
    elseif action == "bluetooth" then
        return process.exec({bluetooth})
    elseif action == "audio" then
        return process.exec({"pavucontrol"})
    elseif action == "files" then
        return process.exec({"nautilus"})
    elseif action == "emoji" then
        return process.exec({emoji})
    elseif action == "clipboard" then
        return process.exec({clipboard})
    elseif action == "calculator" then
        return process.exec({calc})
    elseif action == "screenshot-area" then
        return screenshot(true)
    elseif action == "screenshot-full" then
        return screenshot(false)
    elseif action == "lock" then
        return process.exec({"swaylock", "-f"})
    elseif action == "suspend" then
        return confirm("Suspend") and process.run({"systemctl", "suspend"}) or 0
    elseif action == "logout" then
        if not confirm("Log out") then
            return 0
        end
        local session = os.getenv("XDG_SESSION_ID")
        if session and session ~= "" then
            return process.run({"loginctl", "terminate-session", session})
        end
        return 1
    elseif action == "reboot" then
        return confirm("Restart") and process.run({"systemctl", "reboot"}) or 0
    elseif action == "poweroff" then
        return confirm("Power off") and process.run({"systemctl", "poweroff"}) or 0
    end

    io.stderr:write("unknown action: " .. tostring(action) .. "\n")
    return 2
end

if arg[1] == "--worker" then
    os.exit(worker(arg[2]))
end

local selection = picker.pick(fuzzel, {prompt = "", lines = rows(action_data.entries)})
if not selection then
    os.exit(0)
end
local chosen
for _, entry in ipairs(action_data.entries) do
    if entry.label == selection then
        chosen = entry
        break
    end
end
if not chosen then
    os.exit(0)
end
os.exit(run_detached(chosen.action))
