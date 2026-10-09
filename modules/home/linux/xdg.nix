{pkgs, ...}: {
  xdg = {
    configFile = {
      "hypr/hyprland.lua".source = ../../../config/hypr/hyprland.lua;
      "hypr/scripts/graphical-session.lua".source = ../../../config/hypr/scripts/graphical-session.lua;
      "foot".source = ../../../config/foot;
      "imv".source = ../../../config/imv;
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

    # imv is the only image viewer; make it the default handler. MIME defaults
    # have no wildcard, so list the formats imv's backends support. COSMIC
    # Files is the only file manager, so it owns directories.
    mimeApps.defaultApplications = let
      types = [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/tiff"
        "image/svg+xml"
        "image/avif"
        "image/heif"
        "image/jxl"
        "image/qoi"
        "image/x-farbfeld"
      ];
    in
      builtins.listToAttrs (map (type: {
          name = type;
          value = "imv.desktop";
        })
        types)
      // {
        "inode/directory" = "com.system76.CosmicFiles.desktop";
      };

    # xdg-open's generic Hyprland path does not honor Terminal=true. Launch
    # Neovim in Foot explicitly so browsers and file managers get a window.
    desktopEntries.neovim-terminal = {
      name = "Neovim";
      genericName = "Text Editor";
      comment = "Edit text files";
      exec = "${pkgs.foot}/bin/foot nvim %F";
      icon = "nvim";
      terminal = false;
      categories = ["Utility" "TextEditor" "Development"];
      mimeType = ["text/plain" "text/markdown"];
    };
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
      ExecStart = "${pkgs.axseem.lua.interpreter} ${./text-mime-types.lua} ${pkgs.shared-mime-info}/share/mime/types neovim-terminal.desktop ${pkgs.xdg-utils}/bin/xdg-mime";
      RemainAfterExit = true;
    };
    Install.WantedBy = ["default.target"];
  };
}
