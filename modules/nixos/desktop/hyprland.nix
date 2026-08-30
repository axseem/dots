{pkgs, ...}: {
  programs.hyprland.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    # Wayland utilities
    way-displays
    swaylock
  ];

  security.pam.services.swaylock = {};
}
