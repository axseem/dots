{
  pkgs,
  lib,
  ...
}: let
  theme = import ../../../themes/axterm.nix;
in {
  programs.vscode = {
    enable = true;
    profiles.default.userSettings =
      (builtins.fromJSON (builtins.readFile ../../../../config/vscode/settings.json))
      // {
        "workbench.colorCustomizations" = {
          "terminal.background" = theme.background;
          "terminal.foreground" = theme.foreground;
          "terminalCursor.foreground" = theme.cursor;
          "terminal.selectionBackground" = theme.selection-background;
          "terminal.ansiBlack" = builtins.elemAt theme.palette 0;
          "terminal.ansiRed" = builtins.elemAt theme.palette 1;
          "terminal.ansiGreen" = builtins.elemAt theme.palette 2;
          "terminal.ansiYellow" = builtins.elemAt theme.palette 3;
          "terminal.ansiBlue" = builtins.elemAt theme.palette 4;
          "terminal.ansiMagenta" = builtins.elemAt theme.palette 5;
          "terminal.ansiCyan" = builtins.elemAt theme.palette 6;
          "terminal.ansiWhite" = builtins.elemAt theme.palette 7;
          "terminal.ansiBrightBlack" = builtins.elemAt theme.palette 8;
          "terminal.ansiBrightRed" = builtins.elemAt theme.palette 9;
          "terminal.ansiBrightGreen" = builtins.elemAt theme.palette 10;
          "terminal.ansiBrightYellow" = builtins.elemAt theme.palette 11;
          "terminal.ansiBrightBlue" = builtins.elemAt theme.palette 12;
          "terminal.ansiBrightMagenta" = builtins.elemAt theme.palette 13;
          "terminal.ansiBrightCyan" = builtins.elemAt theme.palette 14;
          "terminal.ansiBrightWhite" = builtins.elemAt theme.palette 15;
        };
      };
  };
}
