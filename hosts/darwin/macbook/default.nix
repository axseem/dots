{
  inputs,
  username,
  ...
}: let
  importTree = import ../../../nix/import-tree.nix;
in {
  imports = [
    (importTree ../../../modules/common)
    (importTree ../../../modules/darwin)

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
