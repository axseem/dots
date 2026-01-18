{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    # Common
    ../../../modules/common/nix.nix
    ../../../modules/common/fonts.nix

    # Darwin
    ../../../modules/darwin/nix.nix
    ../../../modules/darwin/homebrew.nix

    inputs.home-manager.darwinModules.home-manager
  ];

  system.primaryUser = "axseem";

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.axseem = import ./home.nix;
    extraSpecialArgs = {inherit inputs;};
  };

  system.stateVersion = 5;

  networking.hostName = "macbook";
}
