{
  pkgs,
  lib,
  ...
}: {
  programs.vscodium = {
    enable = true;
    profiles.default.userSettings = builtins.fromJSON (builtins.readFile ../../../../config/vscodium/settings.json);
  };
}
