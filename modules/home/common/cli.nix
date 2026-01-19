{
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [
    # Archives
    p7zip
    unzip
    unrar
    zip

    # Search & Navigation
    ripgrep
    fd
    fzf
    tree
    eza
    bat
    zoxide

    # Text & Data Processing
    jq
    yq
    sd
    delta
    miller
    jless

    # System Monitoring
    btop
    dust
    duf
    procs
    bandwhich
    fastfetch

    # Network
    curl
    xh
    socat
    dnsutils
    mtr

    # Git
    gh
    lazygit
    git-lfs

    # Dev Utilities
    direnv
    entr
    watchexec
    hyperfine
    tokei
    just
    act
    pre-commit

    # File Management
    yazi
    trash-cli

    # File Transfer
    rsync
    rclone
    croc

    # Media
    ffmpeg
    imagemagick
    exiftool

    # Security
    age
    gnupg

    # Misc
    openssl
    tldr
    pv
    parallel
    glow
    github-copilot-cli

    inputs.dirmd.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
