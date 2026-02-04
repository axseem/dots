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
    foot

    # Development / Creative
    freecad
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
    godot
    bitsnpicas
  ];
}
