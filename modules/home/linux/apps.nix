{
  inputs,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    # Browser
    brave
    mullvad-browser

    # Communication
    signal-desktop

    # Productivity
    kdePackages.okular
    foot

    # Development / Creative
    inputs.freecad-pkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.freecad
    kicad
    orca-slicer
    darktable
    kdePackages.kdenlive
    gnome-clocks

    proton-vpn

    aseprite
    qbittorrent
    bitsnpicas
    steam
  ];
}
