{
  pkgs,
  inputs,
  ...
}: {
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    GIT_EDITOR = "nvim";
  };

  programs.direnv = {
    enable = true;
    config.global.hide_env_diff = true;
  };

  home.packages = with pkgs; [
    axseem.lua.runtime
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

    # Binary Inspection & Analysis
    fq
    rizin
    vim.xxd

    # WebAssembly
    wasm-tools

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
    axseem.lsnix
    axseem.mk
    entr
    watchexec
    hyperfine
    tokei
    act
    pre-commit

    # File Management
    yazi
    trash-cli

    # File Transfer
    rsync
    rclone
    croc

    # PDF
    poppler-utils

    # Media
    ffmpeg
    imagemagick
    exiftool
    jpegli

    # Security
    age
    bitwarden-cli
    gnupg

    # Misc
    openssl
    tldr
    pv
    parallel
    glow
    github-copilot-cli
    codex
    nodejs
    bun

    inputs.nvim.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.harness.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
