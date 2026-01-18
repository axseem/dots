{pkgs, ...}: {
  home.packages = with pkgs; [
    # Browser
    brave
    mullvad-browser

    # Communication
    signal-desktop
    telegram-desktop

    # Productivity
    bitwarden-desktop
    kdePackages.okular
    ghostty

    # Development / Creative
    # freecad  # Temporarily disabled due to broken openturns dependency
    kicad
    lmstudio
    zed-editor
    orca-slicer
    sniffnet
    claude-code
    sly
    darktable
    opencode

    protonvpn-gui

    prismlauncher
    aseprite
    qbittorrent
  ];
}
