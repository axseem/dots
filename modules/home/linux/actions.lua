#!/usr/bin/env lua

-- Worker for the anyrun actions plugin. The menu entries live in
-- anyrun/actions.ron; this script owns the side effects.
local process = require("axseem.process")

local function trim(value)
    return (value:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function write_file(path, contents)
    local file = assert(io.open(path, "wb"))
    assert(file:write(contents))
    assert(file:close())
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

local function logout()
    local session = os.getenv("XDG_SESSION_ID")
    if session and session ~= "" then
        return process.run({"loginctl", "terminate-session", session})
    end
    return 1
end

local function worker(action)
    if action == "screenshot-area" then
        return screenshot(true)
    elseif action == "screenshot-full" then
        return screenshot(false)
    elseif action == "lock" then
        return process.exec({"swaylock", "-f"})
    elseif action == "suspend" then
        return process.exec({"systemctl", "suspend"})
    elseif action == "logout" then
        return logout()
    elseif action == "reboot" then
        return process.exec({"systemctl", "reboot"})
    elseif action == "poweroff" then
        return process.exec({"systemctl", "poweroff"})
    end

    io.stderr:write("unknown action: " .. tostring(action) .. "\n")
    return 2
end

if arg[1] == "--worker" then
    os.exit(worker(arg[2]))
end

io.stderr:write("usage: actions --worker <action>\n")
os.exit(2)
