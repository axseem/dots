{
  inputs,
  username,
  lib,
  config,
  pkgs,
  ...
}: {
  # The MT7925 Bluetooth USB function can become permanently unresponsive
  # after an autosuspend remote wakeup (kernel error -110). Keep it active;
  # a full power-off is required once the controller is already stuck.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';

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

    # System
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
    ../../../modules/nixos/services/ssh-lan.nix
    ../../../modules/nixos/services/virtualization.nix
    ../../../modules/nixos/services/searxng/module.nix

    # Security
    ../../../modules/nixos/security/hardening.nix

    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    users.${username} = import ./home.nix;
    extraSpecialArgs = {
      inherit inputs username;
    };
  };

  hardware.nvidia-prime = {
    enable = true;
    nvidiaBusId = "PCI:64:00:0";
    amdgpuBusId = "PCI:65:00:0";
  };

  # Libinput (touchpad, keyboard, etc.)
  services.libinput.enable = true;

  # Fontconfig tweaks (NixOS-level; complements common/fonts.nix packages)
  fonts.fontconfig = {
    allowBitmaps = true;
    useEmbeddedBitmaps = true;
  };
  fonts.fontDir.enable = true;

  services.searxng-local.enable = true;

  # Set local SearXNG as default search engine in Chromium
  programs.chromium = {
    enable = true;
    extensions = ["nngceckbapebfimnlniiiahkandclblb"];
    defaultSearchProviderEnabled = true;
    defaultSearchProviderSearchURL = "http://localhost:8888/search?q={searchTerms}";
  };

  system.stateVersion = "25.05";

  networking.hostName = "ideapad";
}
