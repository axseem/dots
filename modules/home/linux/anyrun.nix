{pkgs, ...}: {
  programs.anyrun = {
    enable = true;
    config = {
      x.fraction = 0.5;
      y.fraction = 0.3;
      width.fraction = 0.4;
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = false;
      closeOnClick = true;
      showResultsImmediately = true;
      maxEntries = 12;
      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/librink.so"
        "${pkgs.anyrun}/lib/libsymbols.so"
        "${pkgs.anyrun}/lib/libactions.so"
      ];
    };

    extraConfigFiles = {
      "actions.ron".text = ''
        Config(
          enable_power_actions: false,
          custom_actions: [
            (title: "Wi-Fi settings", command: "wifi", description: "Network connections", icon: "network-wireless-symbolic"),
            (title: "Bluetooth settings", command: "bluetooth", description: "Adapters and devices", icon: "bluetooth-symbolic"),
            (title: "Clipboard history", command: "clipboard", description: "Recent clipboard entries", icon: "edit-paste-symbolic"),
            (title: "Audio settings", command: "pavucontrol", description: "Volume and devices", icon: "audio-volume-high-symbolic"),
            (title: "Browse files", command: "nautilus", description: "File manager", icon: "folder-symbolic"),
            (title: "Screenshot area", command: "actions --worker screenshot-area", description: "Capture a selection", icon: "camera-photo-symbolic"),
            (title: "Screenshot full screen", command: "actions --worker screenshot-full", description: "Capture the display", icon: "camera-photo-symbolic"),
            (title: "Lock screen", command: "actions --worker lock", description: "Lock the session", icon: "system-lock-screen-symbolic"),
            (title: "Suspend", command: "actions --worker suspend", description: "Suspend to RAM", icon: "media-playback-pause-symbolic", confirm: true),
            (title: "Log out", command: "actions --worker logout", description: "End the session", icon: "system-log-out-symbolic", confirm: true),
            (title: "Restart", command: "actions --worker reboot", description: "Reboot the machine", icon: "system-reboot-symbolic", confirm: true),
            (title: "Power off", command: "actions --worker poweroff", description: "Shut down the machine", icon: "system-shutdown-symbolic", confirm: true),
          ],
        )
      '';

      "stdin.ron".text = ''
        Config(
          allow_invalid: false,
          max_entries: 12,
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
      @define-color desc-color #777777;

      window {
        background: transparent;
      }

      box.main {
        padding: 5px;
        margin: 0;
        border-radius: 0;
        border: 1px solid @accent;
        background-color: @bg-color;
        box-shadow: none;
      }

      text {
        min-height: 30px;
        padding: 5px;
        border-radius: 0;
        color: @fg-color;
      }

      .matches {
        background-color: rgba(0, 0, 0, 0);
        border-radius: 0;
      }

      box.plugin:first-child {
        margin-top: 5px;
      }

      list.plugin {
        background-color: rgba(0, 0, 0, 0);
      }

      label.match {
        color: @fg-color;
      }

      label.match.description {
        font-size: 10px;
        color: @desc-color;
      }

      label.plugin.info {
        font-size: 14px;
        color: @fg-color;
      }

      .match {
        background: transparent;
      }

      .match:selected {
        border-left: 4px solid @accent;
        background: transparent;
      }
    '';
  };
}
