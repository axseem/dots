{pkgs, ...}: {
  users.users.root.hashedPassword = "!";

  security.apparmor = {
    enable = true;
    packages = with pkgs; [
      apparmor-utils
      apparmor-profiles
    ];
  };

  services.fail2ban.enable = true;

  security.sudo.execWheelOnly = true;
  security.audit.enable = true;

  environment.systemPackages = with pkgs; [
    vulnix
    seahorse
  ];
}
