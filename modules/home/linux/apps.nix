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
    sly
    darktable

    proton-vpn

    prismlauncher
    aseprite
    qbittorrent
    godot
    bitsnpicas
  ];
}
