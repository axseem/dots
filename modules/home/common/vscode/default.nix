{
  pkgs,
  lib,
  ...
}: {
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = builtins.fromJSON (builtins.readFile ../../../../config/vscode/settings.json);
  };
}
