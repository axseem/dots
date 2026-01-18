{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    p7zip
    unzip
    unrar
    jq
    ffmpeg
    zip
    exiftool
    openssl
    btop
    github-copilot-cli
    imagemagick
    croc

    inputs.dirmd.packages.${pkgs.system}.default
    inputs.nvim.packages.${pkgs.system}.default
  ];
}
