{
  pkgs,
  inputs,
  username,
  config,
  cudaPackages ? false,
  ...
}: {
  imports = [
    ../../../modules/home/common/fish
    ../../../modules/home/common/vscodium
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix
    ../../../modules/home/common/xdg.nix

    ../../../modules/home/linux/ui.nix
    ../../../modules/home/linux/xdg.nix
    ../../../modules/home/linux/cli-linux.nix
    ../../../modules/home/linux/media.nix
    ../../../modules/home/linux/apps.nix
    ../../../modules/home/linux/desktop-utils.nix

    inputs.voxtype.homeManagerModules.default
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.droid
    ];

    sessionVariables = {
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/library/img/screenshots";
      LOCK_CMD = "swaylock -f -c 000000";
    };
  };

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf.d/host.conf".text = ''
    # Monitor Configuration
    monitor = eDP-1, 2880x1800@120.00Hz, 0x0, 2
    monitor = HDMI-A-2, 2560x1440@100.00Hz, 1440x0, 1

    # Host-specific variables
    $lock = swaylock -f -c 000000
  '';

  services.gnome-keyring.enable = true;

  programs.voxtype = {
    enable = true;
    package =
      if cudaPackages
      then inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.onnx-cuda
      else inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.onnx;
    engine = "parakeet";
    service.enable = true;
    settings = {
      hotkey.enabled = false;
      parakeet = {
        model = "parakeet-tdt-0.6b-v3";
        on_demand_loading = true;
      };
      output = {
        mode = "type";
        fallback_to_clipboard = true;
      };
    };
  };

  programs.home-manager.enable = true;
}
