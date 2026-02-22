{
  pkgs,
  inputs,
  username,
  config,
  lib,
  ...
}: {
  imports =
    [
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
    ]
    ++ (
      if builtins.pathExists ./secrets.nix
      then [./secrets.nix]
      else []
    );

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";

    packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.claude-code
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.droid
      inputs.mux.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    sessionVariables = {
      # NOTE: This path is specific to my directory structure.
      # If you are using this config, you might want to change this.
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/library/img/screenshots";
      LOCKSCREEN_PATH = "${config.home.homeDirectory}/me/library/img/wallpaper/lockscreen.png";
      LOCK_CMD = "swaylock -f -i eDP-1:${config.home.homeDirectory}/me/library/img/wallpaper/lockscreen.png";
    };
  };

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf.d/host.conf".text = ''
    # Monitor Configuration
    monitor = eDP-1, 2880x1800@120.00Hz, 0x0, 2
    monitor = HDMI-A-2, 2560x1440@100.00Hz, 1440x0, 1

    # Host-specific variables
    $lock = swaylock -f -i eDP-1:${config.home.sessionVariables.LOCKSCREEN_PATH}
  '';

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;
}
