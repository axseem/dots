{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    inputs.zig.packages.${pkgs.stdenv.hostPlatform.system}.master
    inputs.zls.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
