{
  username,
  lib,
  inputs,
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
      inputs.llama-cpp.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  programs.home-manager.enable = true;
}
