{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.zig
    pkgs.zls
  ];
}
