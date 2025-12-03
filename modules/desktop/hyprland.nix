{pkgs, ...}: {
  programs.hyprland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    # Hyprland ecosystem
    hyprlock
    hypridle
    hyprpaper
    quickshell

    # Screenshot tools
    grim
    slurp

    # Wayland utilities
    swaynotificationcenter
    wl-clipboard
    way-displays
    swaylock
    swww
    swayidle
    foot
  ];

  security.pam.services.hyprlock = {};
}
