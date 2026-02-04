{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    inputs.zig.packages.${pkgs.system}.master
    inputs.zls.packages.${pkgs.system}.default
  ];
}
