{
  inputs,
  pkgs,
  username,
  ...
}: let
  importTree = import ../../../nix/import-tree.nix;
in {
  # The MT7925 Bluetooth USB function can become permanently unresponsive
  # after an autosuspend remote wakeup (kernel error -110). Keep it active;
  # a full power-off is required once the controller is already stuck.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=0
  '';

  # The remote-wakeup hang is fixed upstream in btmtk ("Bluetooth: btmtk:
  # Disable remote wakeup for MT7922/MT7925", e31d7616), which first landed in
  # 7.2. The 6.18 LTS never got the backport. Drop this once the default
  # kernel is >= 7.2.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-ideapad-16ahp9
    ./hardware-configuration.nix
    ./boot.nix
    ./keyboard.nix
    ./power.nix
    ./ssh-lan.nix

    (importTree ../../../modules/common)
    (importTree ../../../modules/nixos)

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

  # programs.chromium mirrors its policy to Brave's policy directory too;
  # disable those outputs so Brave stays unmanaged.
  environment.etc = {
    "brave/policies/managed/default.json".enable = false;
    "brave/policies/managed/extra.json".enable = false;
    "brave/policies/recommended/extra.json".enable = false;
  };

  system.stateVersion = "25.05";

  networking.hostName = "ideapad";
}
