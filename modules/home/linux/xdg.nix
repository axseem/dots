{...}: {
  xdg.configFile = {
    "ghostty".source = ../../../config/ghostty;

    # Hyprland
    "hypr/hyprland.conf".source = ../../../config/hypr/hyprland.conf;
    "hypr/hypridle.conf".source = ../../../config/hypr/hypridle.conf;

    "mako".source = ../../../config/mako;
    "rofi".source = ../../../config/rofi;
    "networkmanager-dmenu".source = ../../../config/networkmanager-dmenu;
    "swaylock".source = ../../../config/swaylock;
    "quickshell".source = ../../../config/quickshell;
    #"qBittorrent".source = ../../../config/qBittorrent;
  };
}
