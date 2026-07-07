{pkgs, ...}: {
  services.xserver = {
    enable = true;
    displayManager.startx.enable = true;
    windowManager.dwm.enable = true;
  };

  environment.systemPackages = [
    pkgs.dmenu
    pkgs.dwm
    pkgs.st
    pkgs.xterm
    pkgs.xrandr
  ];
}
