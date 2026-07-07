{
  username,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../modules/home/common/fish
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix
    ../../../modules/home/common/xdg.nix
    ../../../modules/home/common/vscodium
  ];

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
