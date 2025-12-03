{
  services = {
    devmon.enable = true;
    gvfs.enable = true;
    udisks2.enable = true;
    dbus.enable = true;
    fwupd.enable = true;
  };

  programs = {
    direnv.enable = true;
    dconf.enable = true;

    fish = {
      enable = true;
      interactiveShellInit = ''
        set fish_greeting
      '';
    };
  };
}
