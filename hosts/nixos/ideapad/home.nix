{
  pkgs,
  inputs,
  username,
  config,
  ...
}: {
  imports = [
    inputs.opencode-config.homeModules.default

    ../../../modules/home/common/fish
    ../../../modules/home/common/vscodium
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix

    ../../../modules/home/linux/ui.nix
    ../../../modules/home/linux/xdg.nix
    ../../../modules/home/linux/cli-linux.nix
    ../../../modules/home/linux/media.nix
    ../../../modules/home/linux/apps.nix
    ../../../modules/home/linux/desktop-utils.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    packages = [
      (pkgs.llama-cpp.override {cudaSupport = true;})
    ];

    sessionVariables = {
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/screenshots";
      LOCK_CMD = "swaylock -f -c 000000";
    };
  };

  # Same email as the mac for now; change to a host-specific one if desired.
  programs.git.settings.user.email = "max@axseem.me";

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf.d/host.conf".text = ''
    # Monitor Configuration
    monitor = eDP-1, 2880x1800@120.00Hz, 0x0, 2
    monitor = HDMI-A-2, 2560x1440@100.00Hz, 1440x0, 1

    # Use separate default workspaces in the extended layout.
    workspace = 1, monitor:eDP-1, default:true
    workspace = 10, monitor:HDMI-A-2, default:true

    # With an external display connected, use it as the only display while
    # the lid is closed (device keeps running). Without one, suspend.
    # Both variants are needed: plain `bind` fires only when unlocked, `bindl`
    # only while a lock screen is active (switch events are keybind-gated).
    bind = , switch:on:Lid Switch, exec, sh -c 'hyprctl monitors | grep -q "^Monitor HDMI-A-2 " && { hyprctl keyword monitor "HDMI-A-2,2560x1440@100.00Hz,0x0,1"; hyprctl keyword monitor "eDP-1,disable"; } || systemctl suspend'
    bind = , switch:off:Lid Switch, exec, sh -c 'hyprctl keyword monitor "eDP-1,2880x1800@120.00Hz,0x0,2"; hyprctl keyword monitor "HDMI-A-2,2560x1440@100.00Hz,1440x0,1"'
    bindl = , switch:on:Lid Switch, exec, sh -c 'hyprctl monitors | grep -q "^Monitor HDMI-A-2 " && { hyprctl keyword monitor "HDMI-A-2,2560x1440@100.00Hz,0x0,1"; hyprctl keyword monitor "eDP-1,disable"; } || systemctl suspend'
    bindl = , switch:off:Lid Switch, exec, sh -c 'hyprctl keyword monitor "eDP-1,2880x1800@120.00Hz,0x0,2"; hyprctl keyword monitor "HDMI-A-2,2560x1440@100.00Hz,1440x0,1"'

    # Host-specific variables
    $lock = swaylock -f -c 000000
  '';

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;
}
