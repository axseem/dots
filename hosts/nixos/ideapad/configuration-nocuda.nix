{
  inputs,
  username,
  lib,
  ...
}: {
  imports = [
    ./configuration.nix
  ];

  hardware.nvidia-prime.enable = lib.mkForce false;
  hardware.graphics.enable = true;

  home-manager.extraSpecialArgs.cudaPackages = false;
}
