{
  lib,
  pkgs,
  ...
}: let
  idleCommands = pkgs.axseem.swayidle-commands;
  cliphistWatcher = kind: {
    Unit = {
      Description = "Watch ${kind} clipboard history";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type ${kind} --watch ${pkgs.cliphist}/bin/cliphist store";
      Restart = "on-failure";
    };
    Install.WantedBy = ["graphical-session.target"];
  };
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
    cliphist-text = cliphistWatcher "text";
    cliphist-image = cliphistWatcher "image";
  };

  home.packages = with pkgs; [
    # File Management
    file-roller
    nautilus

    # Utilities
    libqalculate
    brightnessctl
    playerctl
    grim
    slurp
    wl-clipboard

    # System / Desktop Integration
    axseem.actions
    axseem.clipboard
    axseem.emoji
    axseem.wifi
    cliphist
    pavucontrol
    gcr_4
  ];
}
