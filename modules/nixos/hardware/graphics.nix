{config, ...}: {
  hardware.graphics.enable = true;

  services.xserver.videoDrivers = [
    "amdgpu"
    "nvidia"
  ];

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
      nvidiaBusId = "PCI:64:00:0";
      amdgpuBusId = "PCI:65:00:0";
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030000", ATTR{power/control}="auto"
    SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x030200", ATTR{power/control}="auto"
  '';
}
