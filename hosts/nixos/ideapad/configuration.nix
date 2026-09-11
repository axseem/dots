{
  inputs,
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

  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-ideapad-16ahp9
    ./hardware-configuration.nix

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
