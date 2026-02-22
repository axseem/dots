{
  pkgs,
  inputs,
  username,
  config,
  lib,
  ...
}: {
  imports = [
    ../../../modules/home/common/fish
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix
    ../../../modules/home/common/xdg.nix
    ../../../modules/home/common/vscode
  ];

  #programs.llama-cpp.enable = true;

  home = {
    inherit username;
    homeDirectory = lib.mkForce "/Users/${username}";
    stateVersion = "25.11";

    packages = [
      pkgs.claude-code
    ];
  };

  programs.home-manager.enable = true;
}
