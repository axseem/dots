{pkgs, ...}: {
  programs.anyrun = {
    enable = true;
    config = {
      x.fraction = 0.5;
      y.fraction = 0.3;
      width.fraction = 0.4;
      # anyrun hardcodes 32 px match rows and icons and has no placeholder
      # option for the entry field; both limits come from upstream, not config.
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = true;
      showResultsImmediately = false;
      maxEntries = 8;
      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/librink.so"
        "${pkgs.anyrun}/lib/libactions.so"
      ];
    };

    extraConfigFiles = {
      "actions.ron".text = ''
        Config(
          enable_power_actions: false,
          // commands are run through sh -c; the actions plugin waits for their
          // stdout and stderr to reach EOF before closing its window, and a
          // detached process inherits those pipes, so redirect them or the
          // launcher stays open until the detached program exits
          custom_actions: [
            (title: "Wi-Fi settings", command: "setsid -f wifi >/dev/null 2>&1", description: "Network connections", icon: "network-wireless-symbolic"),
            (title: "Clipboard history", command: "setsid -f clipboard >/dev/null 2>&1", description: "Recent clipboard entries", icon: "edit-paste-symbolic"),
            (title: "Emoji picker", command: "setsid -f emoji >/dev/null 2>&1", description: "Search and copy an emoji", icon: "face-smile-symbolic"),
            (title: "Audio settings", command: "setsid -f pavucontrol >/dev/null 2>&1", description: "Volume and devices", icon: "audio-volume-high-symbolic"),
            (title: "Browse files", command: "setsid -f cosmic-files >/dev/null 2>&1", description: "File manager", icon: "folder-symbolic"),
            (title: "Screenshot area", command: "setsid -f actions --worker screenshot-area >/dev/null 2>&1", description: "Capture a selection", icon: "camera-photo-symbolic"),
            (title: "Screenshot full screen", command: "setsid -f actions --worker screenshot-full >/dev/null 2>&1", description: "Capture the display", icon: "camera-photo-symbolic"),
            (title: "Lock screen", command: "setsid -f actions --worker lock >/dev/null 2>&1", description: "Lock the session", icon: "system-lock-screen-symbolic"),
            (title: "Suspend", command: "setsid -f actions --worker suspend >/dev/null 2>&1", description: "Suspend to RAM", icon: "media-playback-pause-symbolic", confirm: true),
            (title: "Log out", command: "setsid -f actions --worker logout >/dev/null 2>&1", description: "End the session", icon: "system-log-out-symbolic", confirm: true),
            (title: "Restart", command: "setsid -f actions --worker reboot >/dev/null 2>&1", description: "Reboot the machine", icon: "system-reboot-symbolic", confirm: true),
            (title: "Power off", command: "setsid -f actions --worker poweroff >/dev/null 2>&1", description: "Shut down the machine", icon: "system-shutdown-symbolic", confirm: true),
          ],
        )
      '';

      "stdin.ron".text = ''
        Config(
          allow_invalid: false,
          max_entries: 64,
          preserve_order: false,
        )
      '';

      "rink.ron".text = ''
        Config(
          prefix: "",
        )
      '';
    };

    extraCss = ''
      @define-color accent #222222;
      @define-color bg-color #000000;
      @define-color fg-color #ffffff;
      @define-color muted-color #777777;

      window {
        background: transparent;
      }

      box.main,
      text,
      .matches {
        border-radius: 0;
        background-color: @bg-color;
      }

      box.main {
        padding: 0;
        margin: 0;
        border: 1px solid @accent;
        box-shadow: none;
      }

      text {
        min-height: 0;
        margin: 0;
        padding: 8px 12px;
        border: 0;
        border-bottom: 1px solid @accent;
        color: @fg-color;
        caret-color: @fg-color;
        font-family: "Inter";
        font-size: 11pt;
      }

      .matches {
        padding: 2px;
      }

      box.plugin,
      list.plugin {
        margin: 0;
        padding: 0;
        border-radius: 0;
        background-color: transparent;
      }

      .match {
        min-height: 0;
        border: 0;
        border-radius: 0;
        padding: 0;
        background: transparent;
      }

      row.match {
        padding: 3px 8px;
      }

      label.match.title {
        font-size: 11pt;
        color: @fg-color;
      }

      label.match.description {
        font-size: 9pt;
        color: @muted-color;
      }

      .match:selected {
        background-color: @fg-color;
      }

      .match:selected label.title,
      .match:selected label.description {
        color: @bg-color;
      }
    '';
  };
}
