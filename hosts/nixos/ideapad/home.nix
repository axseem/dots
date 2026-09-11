{
  pkgs,
  username,
  config,
  ...
}: let
  importTree = import ../../../nix/import-tree.nix;
in {
  imports = [
    (importTree ../../../modules/home/common)
    (importTree ../../../modules/home/linux)
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
    };
  };

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf/host.lua".source = ../../../config/hypr/conf/host.lua;

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;
}
