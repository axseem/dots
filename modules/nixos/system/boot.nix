{pkgs, ...}: {
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd.systemd.enable = true;
    # kernelPackages = pkgs.linuxPackages_latest;

    # Kernel parameters to improve stability and prevent freezes
    kernelParams = [
      # Disable NVIDIA memory preservation - can cause freezes with PRIME offload on newer GPUs
      "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
      # Explicitly enable NMI watchdog for better hang detection
      "nmi_watchdog=1"
    ];
  };
  hardware.enableAllFirmware = true;
}
