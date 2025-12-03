{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Browser
    brave

    # Communication
    signal-desktop
    telegram-desktop

    # Productivity
    bitwarden-desktop
    kdePackages.okular
    ghostty

    # Development / Creative
    freecad
    kicad
    lmstudio
    zed-editor
    orca-slicer
    sniffnet

    protonvpn-gui
  ];
}
