{
  inputs,
  username,
  pkgs,
  ...
}: {
  imports = [
    # Common
    ../../../modules/common/nix.nix
    ../../../modules/common/fonts.nix
    ../../../modules/common/llama.nix

    # Darwin
    ../../../modules/darwin/nix.nix
    ../../../modules/darwin/homebrew.nix
    ../../../modules/darwin/system.nix
    ../../../modules/darwin/dev-tools.nix

    inputs.home-manager.darwinModules.home-manager
  ];

  system.primaryUser = username;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${username} = import ./home.nix;
    extraSpecialArgs = {inherit inputs username;};
  };

  system.stateVersion = 5;

  networking.hostName = "macbook";
}
