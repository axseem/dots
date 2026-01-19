{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    postgresql
  ];
}
