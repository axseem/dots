{
  inputs,
  username,
  lib,
  pkgs,
  ...
}: let
  importTree = import ../../../nix/import-tree.nix;
in {
  imports = [
    inputs.opencode-config.homeModules.default

    (importTree ../../../modules/home/common)
  ];

  xdg.configFile."ghostty".source = ../../../config/ghostty;

  programs.git.settings.user.email = "max@axseem.me";

  # Rebuilding an index for every installed man page is slow and only powers
  # apropos/whatis searches and man-page name completion.
  programs.man.generateCaches = false;

  home = {
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
    stateVersion = "25.11";

    sessionPath = [
      "/opt/homebrew/bin"
      "/opt/homebrew/sbin"
    ];

    packages = [
      pkgs.claude-code
      pkgs.llama-cpp
    ];
  };

  programs.home-manager.enable = true;

  programs.opencode.settings.mcp.mcp_atlassian = {
    type = "remote";
    url = "https://mcp.atlassian.com/v1/mcp/authv2";
    oauth = {};
    enabled = true;
  };

  programs.opencode.settings.mcp.mcp_figma = {
    type = "remote";
    url = "http://127.0.0.1:3845/mcp";
    oauth = false;
    enabled = true;
  };
}
