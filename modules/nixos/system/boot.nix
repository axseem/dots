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

    kernelParams = [
      "nvidia.NVreg_PreserveVideoMemoryAllocations=0"
      "nmi_watchdog=1"
      "amd_pstate=active"
      "pcie_aspm=powersave"
    ];
  };
  hardware.enableAllFirmware = true;
}
