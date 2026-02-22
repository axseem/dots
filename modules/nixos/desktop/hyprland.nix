{pkgs, ...}: {
  programs.hyprland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    # Screenshot tools
    grim
    slurp

    # Wayland utilities
    swaynotificationcenter
    wl-clipboard
    way-displays
    swaylock
    swayidle
    foot
  ];

  security.pam.services.swaylock = {};
}
