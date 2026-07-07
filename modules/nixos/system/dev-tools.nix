{pkgs, ...}: let
  zerostack = pkgs.callPackage ../../../pkgs/zerostack.nix {};
in {
  environment.systemPackages = with pkgs; [
    zerostack
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
    (python3Packages.pipx.overridePythonAttrs (old: {doCheck = false;}))
  ];
}
