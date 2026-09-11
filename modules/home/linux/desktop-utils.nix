{
  lib,
  pkgs,
  ...
}: let
  idleCommands = pkgs.axseem.swayidle-commands;
in {
  services = {
    swaync.enable = true;
    swayidle = {
      enable = true;
      events.before-sleep = "${idleCommands}/bin/swayidle-lock";
      timeouts = [
        {
          timeout = 180;
          command = "${idleCommands}/bin/swayidle-lock";
        }
        {
          timeout = 240;
          command = "${idleCommands}/bin/swayidle-displays-off";
          resumeCommand = "${idleCommands}/bin/swayidle-displays-on";
        }
      ];
    };
  };

  systemd.user.services = {
    swayidle.Service.Environment = lib.mkForce [
      "PATH=${lib.makeBinPath [pkgs.axseem.lua.runtime pkgs.swaylock pkgs.hyprland]}"
    ];
    cliphist-text = {
      Unit = {
        Description = "Watch text clipboard history";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
    cliphist-image = {
      Unit = {
        Description = "Watch image clipboard history";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
        Restart = "on-failure";
      };
      Install.WantedBy = ["graphical-session.target"];
    };
  };

  home.packages = with pkgs; [
    # File Management
    file-roller
    nautilus

    # Utilities
    qalculate-gtk
    libqalculate
    brightnessctl
    playerctl
    grim
    slurp
    wl-clipboard

    # System / Desktop Integration
    (rofi.override {plugins = [rofi-emoji rofi-calc];})
    cliphist
    networkmanager_dmenu
    pavucontrol
    gcr_4
  ];
}
