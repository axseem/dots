{
  config,
  lib,
  ...
}:
with lib; let
  cfg = config.hardware.nvidia-prime;
in {
  options.hardware.nvidia-prime = {
    enable = mkEnableOption "NVIDIA + AMD hybrid graphics with PRIME offload";

    nvidiaBusId = mkOption {
      type = types.str;
      description = "Bus ID for the NVIDIA GPU.";
      example = "PCI:64:00:0";
    };

    amdgpuBusId = mkOption {
      type = types.str;
      description = "Bus ID for the AMD GPU.";
      example = "PCI:65:00:0";
    };
  };

  config = mkIf cfg.enable {
    hardware.graphics.enable = true;

    boot.kernelParams = ["nvidia.NVreg_PreserveVideoMemoryAllocations=0"];

    services.xserver.videoDrivers = ["amdgpu" "nvidia"];

    hardware.nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      open = true;
      modesetting.enable = true;
      powerManagement = {
        enable = true;
        finegrained = false;
      };
      nvidiaSettings = true;
      prime = {
        offload = {
          enable = true;
          enableOffloadCmd = true;
        };
        inherit (cfg) nvidiaBusId amdgpuBusId;
      };
    };

    services.udev.extraRules = ''
      SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
      SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", ATTR{power/control}="auto"
    '';
  };
}
