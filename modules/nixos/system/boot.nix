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
      "nmi_watchdog=1"
      "amd_pstate=active"
      "pcie_aspm=powersave"
    ];
  };
  hardware.enableAllFirmware = true;
}
