{
  inputs,
  username,
  ...
}: {
  imports = [
    ./configuration.nix
  ];

  hardware.nvidia-prime.enable = false;
  hardware.graphics.enable = true;

  home-manager.extraSpecialArgs.cudaPackages = false;
}
