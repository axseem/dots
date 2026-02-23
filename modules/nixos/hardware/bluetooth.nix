{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
    settings.General.Experimental = true;
  };

  services.blueman.enable = true;
}
