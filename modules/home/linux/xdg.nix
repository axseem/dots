{pkgs, ...}: let
  lua = import ../../../nix/lua.nix {inherit pkgs;};
in {
  xdg.configFile = {
    "hypr/hyprland.lua".source = ../../../config/hypr/hyprland.lua;
    "foot".source = ../../../config/foot;
    "rofi".source = ../../../config/rofi;
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

  # xdg-open's generic Hyprland path does not honor Terminal=true. Launch
  # Neovim in Foot explicitly so browsers and file managers get a window.
  xdg.desktopEntries.neovim-terminal = {
    name = "Neovim";
    genericName = "Text Editor";
    comment = "Edit text files";
    exec = "${pkgs.foot}/bin/foot nvim %F";
    icon = "nvim";
    terminal = false;
    categories = ["Utility" "TextEditor" "Development"];
    mimeType = ["text/plain" "text/markdown"];
  };

  # MIME defaults do not support wildcards. A oneshot updates every standard
  # text type while preserving unrelated defaults in mimeapps.list.
  systemd.user.services.neovim-text-mime-types = {
    Unit = {
      Description = "Set Neovim as the default text MIME handler";
      X-Restart-Triggers = [
        "${pkgs.shared-mime-info}/share/mime/types"
        "${./text-mime-types.lua}"
      ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lua.interpreter} ${./text-mime-types.lua} ${pkgs.shared-mime-info}/share/mime/types neovim-terminal.desktop ${pkgs.xdg-utils}/bin/xdg-mime";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["default.target"];
  };
}
