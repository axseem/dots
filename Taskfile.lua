-- dots tasks. Run with `mk [task]`. Bodies are argv values; no shell.
default("check")

local nix = bin("nix")

task("fmt", nix("fmt"))
task("check", nix("flake", "check"))
task("update", nix("flake", "update"))
task("dev", nix("develop"))
task("switch", cmd("sudo", "nixos-rebuild", "switch", "--flake", ".#ideapad"))
task("darwin", cmd("darwin-rebuild", "switch", "--flake", ".#macbook"))
