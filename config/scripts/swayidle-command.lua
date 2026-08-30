#!/usr/bin/env lua

local process = require("axseem.process")
local command = arg[0]:match("([^/]+)$")

if command == "swayidle-lock" then
    process.exec({ "swaylock", "-f" })
elseif command == "swayidle-displays-off" then
    process.exec({ "hyprctl", "dispatch", "dpms", "off" })
elseif command == "swayidle-displays-on" then
    process.exec({ "hyprctl", "dispatch", "dpms", "on" })
else
    io.stderr:write("unknown swayidle command: " .. tostring(command) .. "\n")
    os.exit(2)
end
