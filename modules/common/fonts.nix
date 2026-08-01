{
  pkgs,
  inputs,
  ...
}: {
  fonts.packages = with pkgs; [
    inputs.iosevka-unambiguous.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.abstruct.packages.${pkgs.stdenv.hostPlatform.system}.abstruct-all
    cozette
    creep
    jetbrains-mono
    inter
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    dejavu_fonts
  ];
}
