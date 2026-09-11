{pkgs, ...}: let
  lua = import ../../../nix/lua.nix {inherit pkgs;};
in {
  environment.systemPackages = with pkgs; [
    android-tools
    clang
    clang-tools
    lld
    cmake
    gcc
    go
    zig
    zls
    lua.runtime
    gotools
    delve
    air
    cargo
    rustc
    rust-analyzer
    pnpm
    uv
    ruff
    ty
    python3
    iamb
  ];
}
