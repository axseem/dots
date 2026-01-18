{
  config,
  pkgs,
  ...
}: {
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "power";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 40;

      # Disable PLATFORM_PROFILE to avoid conflict with AMD PMF
      # PLATFORM_PROFILE_ON_AC = "balanced";
      # PLATFORM_PROFILE_ON_BAT = "low-power";

      START_CHARGE_THRESH_BAT0 = 80;
      STOP_CHARGE_THRESH_BAT0 = 80;

      DEVICES_TO_ENABLE_ON_STARTUP = "bluetooth";
    };
  };

  services.logind.settings.Login.HandleLidSwitch = "suspend";

  zramSwap.enable = true;
}
