{
  lib,
  pkgs,
  ...
}: let
  lua = import ../../../nix/lua.nix {inherit pkgs;};
  swayidle = pkgs.swayidle.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./swayidle-direct-command.patch];
  });
  idleCommand = pkgs.writeTextFile {
    name = "swayidle-command";
    destination = "/libexec/swayidle-command.lua";
    executable = true;
    text = builtins.readFile ../../../config/scripts/swayidle-command.lua;
  };
  idleCommands = pkgs.linkFarm "swayidle-commands" [
    {
      name = "bin/swayidle-lock";
      path = "${idleCommand}/libexec/swayidle-command.lua";
    }
    {
      name = "bin/swayidle-displays-off";
      path = "${idleCommand}/libexec/swayidle-command.lua";
    }
    {
      name = "bin/swayidle-displays-on";
      path = "${idleCommand}/libexec/swayidle-command.lua";
    }
  ];
in {
  services = {
    swaync.enable = true;
    swayidle = {
      enable = true;
      package = swayidle;
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
      "PATH=${lib.makeBinPath [lua.runtime pkgs.swaylock pkgs.hyprland]}"
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
    grim
    slurp
    wl-clipboard

    # System / Desktop Integration
    (rofi.override {plugins = [rofi-emoji rofi-calc];})
    cliphist
    networkmanager_dmenu
    pavucontrol
    gcr
  ];
}
