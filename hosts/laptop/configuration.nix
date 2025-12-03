{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Hardware
    inputs.nixos-hardware.nixosModules.lenovo-ideapad-16ahp9
    ./hardware-configuration.nix
    ../../modules/hardware/graphics.nix
    ../../modules/hardware/audio.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/hardware/power.nix
    ../../modules/hardware/input.nix

    # System core
    ../../modules/system/boot.nix
    ../../modules/system/nix.nix
    ../../modules/system/networking.nix
    ../../modules/system/locale.nix
    ../../modules/system/fonts.nix
    ../../modules/system/users.nix
    ../../modules/system/dev-tools.nix
    ../../modules/system/audio-production.nix

    # Desktop environment
    ../../modules/desktop/hyprland.nix
    ../../modules/desktop/display-manager.nix

    # Services
    ../../modules/services/system.nix
    ../../modules/services/virtualization.nix

    # Security
    ../../modules/security/hardening.nix

    # Home Manager
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.axseem = import ./home.nix;
    extraSpecialArgs = {inherit inputs;};
  };

  system.stateVersion = "25.05";
  
  networking.hostName = "laptop";
}

