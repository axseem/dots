{
  pkgs,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default.userSettings = builtins.fromJSON (builtins.readFile ../../../../config/vscodium/settings.json);
  };
}
