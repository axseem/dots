{
  inputs,
  username,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-ideapad-16ahp9
    ./hardware-configuration.nix

    # Common
    ../../../modules/common/nix.nix
    ../../../modules/common/fonts.nix

    # Hardware
    ../../../modules/nixos/hardware/graphics.nix
    ../../../modules/nixos/hardware/audio.nix
    ../../../modules/nixos/hardware/bluetooth.nix
    ../../../modules/nixos/hardware/power.nix
    ../../../modules/nixos/hardware/input.nix

    # System
    ../../../modules/nixos/system/nix.nix
    ../../../modules/nixos/system/boot.nix
    ../../../modules/nixos/system/networking.nix
    ../../../modules/nixos/system/locale.nix
    ../../../modules/nixos/system/users.nix
    ../../../modules/nixos/system/dev-tools.nix
    ../../../modules/nixos/system/audio-production.nix

    # Desktop
    ../../../modules/nixos/desktop/hyprland.nix
    ../../../modules/nixos/desktop/display-manager.nix

    # Services
    ../../../modules/nixos/services/system.nix
    ../../../modules/nixos/services/virtualization.nix

    # Security
    ../../../modules/nixos/security/hardening.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${username} = import ./home.nix;
    extraSpecialArgs = {inherit inputs username;};
  };

  system.stateVersion = "25.05";

  networking.hostName = "ideapad";
}
