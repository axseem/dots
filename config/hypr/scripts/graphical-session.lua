#!/usr/bin/env lua

local process = require("axseem.process")

assert(process.run({
    "systemctl",
    "--user",
    "import-environment",
    "WAYLAND_DISPLAY",
    "XDG_CURRENT_DESKTOP",
    "HYPRLAND_INSTANCE_SIGNATURE",
}) == 0)
assert(process.run({"systemctl", "--user", "start", "graphical-session.target"}) == 0)
