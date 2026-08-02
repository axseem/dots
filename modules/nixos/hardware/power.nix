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
    };
  };

  systemd.services.ideapad-conservation = {
    description = "Enable IdeaPad battery conservation mode";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      # systemd does not support redirection in ExecStart; the glob must also
      # be expanded by the shell.
      ExecStart = "${pkgs.bash}/bin/bash -c 'echo 1 > /sys/bus/platform/drivers/ideapad_acpi/*/conservation_mode'";
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  zramSwap.enable = true;
}
