{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    # Archives
    p7zip
    unzip
    unrar

    # Utils
    jq
    ffmpeg
    brightnessctl
    playerctl
    zip
    exiftool
    openssl
    btop
    github-copilot-cli
    imagemagick

    # Custom
    inputs.dirmd.packages.${pkgs.system}.default
    inputs.nvim.packages.${pkgs.system}.default
  ];
}
