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
-- graphical-session.target refuses manual starts; NixOS's fake session target
-- binds to it, so starting the fake target activates the real one.
assert(process.run({"systemctl", "--user", "start", "nixos-fake-graphical-session.target"}) == 0)
