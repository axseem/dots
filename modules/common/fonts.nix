{pkgs, ...}: {
  fonts.packages = with pkgs; [
    cozette
    creep
    jetbrains-mono
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
  ];
}
