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
    air
    cargo
    rustc
    rust-analyzer
    postgresql
    pnpm
    uv
    ruff
    ty
    python3
    python3Packages.pip
    pipx
  ];
}
