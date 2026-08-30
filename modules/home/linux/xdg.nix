{
  lib,
  pkgs,
  ...
}: {
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

  # MIME defaults do not support wildcards, so register Neovim for every
  # standard text MIME type individually while preserving unrelated defaults.
  home.activation.neovimTextMimeTypes = lib.hm.dag.entryAfter ["writeBoundary"] ''
    while IFS= read -r mimeType; do
      case "$mimeType" in
        text/*)
          $DRY_RUN_CMD ${pkgs.xdg-utils}/bin/xdg-mime default neovim-terminal.desktop "$mimeType"
          ;;
      esac
    done < ${pkgs.shared-mime-info}/share/mime/types
  '';
}
