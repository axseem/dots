{pkgs, ...}: {
  home.packages = with pkgs; [
    # Viewers
    vlc
    mpv
    eog
    gthumb
    cheese
    audacious
    loupe

    # Editors/Creation
    gimp
    obs-studio
    krita
  ];
}
