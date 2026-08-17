{pkgs, ...}: {
  home.packages = with pkgs; [
    # Browser
    brave
    mullvad-browser

    # Communication
    signal-desktop

    # Productivity
    bitwarden-desktop
    kdePackages.okular
    foot

    # Development / Creative
    pkgs.freecad
    kicad
    orca-slicer
    darktable
    kdePackages.kdenlive
    gnome-clocks

    proton-vpn

    aseprite
    qbittorrent
  ];
}
