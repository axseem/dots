{
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    ../../modules/home/fish
    ../../modules/home/vscode
    ../../modules/home/git.nix
    ../../modules/home/ui.nix
    ../../modules/home/xdg.nix
    
    ../../modules/home/cli.nix
    ../../modules/home/media.nix
    ../../modules/home/apps.nix
    ../../modules/home/desktop-utils.nix
  ] ++ (if builtins.pathExists ./secrets.nix then [ ./secrets.nix ] else []);

  home = {
    username = "axseem";
    homeDirectory = "/home/${config.home.username}";
    stateVersion = "25.11";

    sessionVariables = {
      # NOTE: This path is specific to my directory structure.
      # If you are using this config, you might want to change this.
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/library/img/screenshots";
      WALLPAPER_PATH = "${config.home.homeDirectory}/me/library/img/wallpaper/cat.png";
      LOCKSCREEN_PATH = "${config.home.homeDirectory}/me/library/img/wallpaper/lockscreen.png";
      LOCK_CMD = "swaylock -f -i eDP-1:${config.home.homeDirectory}/me/library/img/wallpaper/lockscreen.png";
    };

    packages = [
      inputs.dirmd.packages.${pkgs.system}.default
    ];
  };

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf.d/host.conf".text = ''
    # Monitor Configuration
    monitor = eDP-1, 2880x1800@120.00Hz, 0x0, 2
    monitor = HDMI-A-2, 2560x1440@100.00Hz, 1440x0, 1

    # Host-specific variables
    $lock = swaylock -f -i eDP-1:${config.home.sessionVariables.LOCKSCREEN_PATH}
  '';

  # Host-specific Hyprpaper Configuration
  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${config.home.sessionVariables.WALLPAPER_PATH}
    wallpaper = , ${config.home.sessionVariables.WALLPAPER_PATH}
  '';

  programs.neovim.enable = false;

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;
}
