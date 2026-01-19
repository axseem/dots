{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    clang
    clang-tools
    lld
    cmake
    gcc
    go
    gotools
    delve
    cargo
    rustc
    rust-analyzer
    bun
    docker-compose
    postgresql
    pnpm
    zig
    zls
    uv
    ruff
    ty
    python3
    python3Packages.pip
    pipx
  ];
}
