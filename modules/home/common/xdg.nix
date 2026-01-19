{config, ...}: {
  xdg.configFile = {
    "ghostty".source = ../../../config/ghostty;
    "ai".source = ../../../config/ai;
  };

  # Symlink ~/.claude/CLAUDE.md to our managed file
  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${config.xdg.configHome}/ai/CLAUDE.md";
}
