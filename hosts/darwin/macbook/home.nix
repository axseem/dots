{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../../modules/home/common/fish
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
  ];

  home = {
    username = "axseem";
    homeDirectory = lib.mkForce "/Users/axseem";
    stateVersion = "25.11";
  };

  programs.home-manager.enable = true;
}
