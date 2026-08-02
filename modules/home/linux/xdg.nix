{...}: {
  xdg.configFile = {
    "hypr/hyprland.conf".source = ../../../config/hypr/hyprland.conf;
    "foot".source = ../../../config/foot;
    "rofi".source = ../../../config/rofi;
    "networkmanager-dmenu".source = ../../../config/networkmanager-dmenu;
    "swaylock".source = ../../../config/swaylock;
    # qBittorrent rewrites its config on exit and a future WebUI enablement
    # would persist a password hash into it; manage only the stable keys here
    # and keep the live file untracked (see .gitignore).
    "qBittorrent/qBittorrent.conf".text = ''
      [BitTorrent]
      Session\Interface=proton0
      Session\InterfaceName=proton0
    '';
  };
}
