{
  pkgs,
  inputs,
  username,
  config,
  ...
}: {
  imports = [
    inputs.opencode-config.homeModules.default

    ../../../modules/home/common/fish
    ../../../modules/home/common/tmux.nix
    ../../../modules/home/common/vscodium
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix

    ../../../modules/home/linux/ui.nix
    ../../../modules/home/linux/xdg.nix
    ../../../modules/home/linux/cli-linux.nix
    ../../../modules/home/linux/media.nix
    ../../../modules/home/linux/apps.nix
    ../../../modules/home/linux/desktop-utils.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    packages = [
      (pkgs.llama-cpp.override {cudaSupport = true;})
    ];

    sessionVariables = {
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/screenshots";
      LOCK_CMD = "swaylock -f -c 000000";
    };
  };

  # Same email as the mac for now; change to a host-specific one if desired.
  programs.git.settings.user.email = "max@axseem.me";

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf/host.lua".source = ../../../config/hypr/conf/host.lua;

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;
}
