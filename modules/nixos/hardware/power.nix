{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [pkgs.powertop];

  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      # MT7925 bluetooth: exclude from autosuspend (kernel -110 wakeup bug) and
      # keep the device powered on at startup (bluetooth|nfc|wifi|wwan values).
      # Note: nixpkgs' TLP module masks systemd-rfkill, so no rfkill warning.
      USB_EXCLUDE_BTUSB = 1;
      DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth";
    };
  };

  systemd.tmpfiles.rules = [
    "w- /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode - - - - 1"
  ];

  systemd.services.ideapad-conservation = {
    description = "Enable IdeaPad battery conservation mode";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      # Run after boot-time tmpfiles in case ideapad_acpi appeared later.
      ExecStart = "${pkgs.systemd}/bin/systemd-tmpfiles --create --prefix=/sys/bus/platform/drivers/ideapad_acpi";
    };
  };

  # Hyprland owns lid handling (see hosts/nixos/ideapad/home.nix): closing
  # the lid with an external display connected switches to that display and
  # keeps running; otherwise the lid bind suspends. logind must not preempt
  # the bind, so its lid action is ignored. Note: with no Hyprland session
  # (e.g. at the greeter) closing the lid does nothing.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
  };

  zramSwap.enable = true;
}
