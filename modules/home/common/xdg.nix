{config, lib, ...}: let
  theme = import ../../themes/axterm.nix;
in {
  xdg.configFile = {
    "ghostty/config".source = ../../../config/ghostty/config;
    "ghostty/themes/Carbonfox".source = ../../../config/ghostty/themes/Carbonfox;
    "foot".source = ../../../config/foot;
    "ai".source = ../../../config/ai;
  };

  # Generate Ghostty Theme
  xdg.configFile."ghostty/themes/axterm".text = ''
    palette = 0=${builtins.elemAt theme.palette 0}
    palette = 1=${builtins.elemAt theme.palette 1}
    palette = 2=${builtins.elemAt theme.palette 2}
    palette = 3=${builtins.elemAt theme.palette 3}
    palette = 4=${builtins.elemAt theme.palette 4}
    palette = 5=${builtins.elemAt theme.palette 5}
    palette = 6=${builtins.elemAt theme.palette 6}
    palette = 7=${builtins.elemAt theme.palette 7}
    palette = 8=${builtins.elemAt theme.palette 8}
    palette = 9=${builtins.elemAt theme.palette 9}
    palette = 10=${builtins.elemAt theme.palette 10}
    palette = 11=${builtins.elemAt theme.palette 11}
    palette = 12=${builtins.elemAt theme.palette 12}
    palette = 13=${builtins.elemAt theme.palette 13}
    palette = 14=${builtins.elemAt theme.palette 14}
    palette = 15=${builtins.elemAt theme.palette 15}
    background = ${lib.removePrefix "#" theme.background}
    foreground = ${lib.removePrefix "#" theme.foreground}
    cursor-color = ${lib.removePrefix "#" theme.cursor}
    selection-background = ${lib.removePrefix "#" theme.selection-background}
    selection-foreground = ${lib.removePrefix "#" theme.selection-foreground}
  '';

  # Symlink ~/.claude/CLAUDE.md to our managed file
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/ai/CLAUDE.md";
}
