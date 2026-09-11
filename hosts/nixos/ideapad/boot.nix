{
  pkgs,
  inputs,
  ...
}: let
  # 24px (2x) console font: PSF for the Linux vt, exact bitmap TTF strikes
  # for foot/swaylock. Built in the abstruct flake (pure Abstruct, MIT);
  # all four styles are scaled so no single strike shadows the others in
  # fontconfig (foot requests Abstruct:pixelsize=24 on HiDPI).
  abstructConsoleFont =
    inputs.abstruct.lib.${pkgs.stdenv.hostPlatform.system}.mkScaledFont {scale = 2;};
in {
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 5;
      };
      efi = {
        canTouchEfiVariables = true;
        efiSysMountPoint = "/boot";
      };
    };
    initrd.systemd.enable = true;

    kernelParams = [
      "nmi_watchdog=1"
      "pcie_aspm=powersave"
    ];
  };

  # Loading amdgpu replaces simpledrm's framebuffer and resets its console
  # font. Apply vconsole settings only after that handoff; the initrd password
  # agent already orders itself after systemd-vconsole-setup.
  boot.initrd.systemd.services.systemd-vconsole-setup.after = [
    "systemd-modules-load.service"
  ];

  hardware.enableAllFirmware = true;

  fonts.packages = [abstructConsoleFont];

  console = {
    earlySetup = true;
    font = "abstruct-regular-2x";
    packages = [abstructConsoleFont];
    colors = [
      "000000"
      "CC7777"
      "77BBAA"
      "DDBB88"
      "7788CC"
      "7766BB"
      "77AACC"
      "FFFFFF"
      "777788"
      "FFBBCC"
      "99FFBB"
      "FFDD99"
      "BBDDFF"
      "CCAAFF"
      "CCFFFF"
      "DDDDDD"
    ];
  };
}
