{pkgs, ...}: {
  home.packages = with pkgs; [
    # Viewers
    vlc
    mpv
    imv
    cheese
    audacious

    # Editors/Creation
    gimp
    obs-studio
    krita
  ];
}
