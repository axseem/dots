{
  inputs,
  username,
  lib,
  pkgs,
  ...
}: {
  imports = [
    inputs.opencode-config.homeModules.default

    ../../../modules/home/common/fish
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix
    ../../../modules/home/common/vscodium
  ];

  xdg.configFile."ghostty".source = ../../../config/ghostty;

  programs.git.settings.user.email = "max@axseem.me";

  home = {
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
    stateVersion = "25.11";

    packages = [
      pkgs.llama-cpp
    ];
  };

  programs.home-manager.enable = true;
}
