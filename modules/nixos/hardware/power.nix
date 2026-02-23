{
  config,
  pkgs,
  ...
}: {
  environment.systemPackages = [ pkgs.powertop ];

  services.tlp = {
    enable = true;
    settings = {
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 1;
      DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth";
    };
  };

  systemd.services.ideapad-conservation = {
    description = "Enable IdeaPad battery conservation mode";
    wantedBy = [ "multi-user.target" ];
    after = [ "sysfs.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/echo 1 > /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode";
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  zramSwap.enable = true;
}
