{pkgs, ...}: {
  users.users.root.hashedPassword = "!";

  # NOTE: AppArmor is enabled with default profiles only.
  # No custom profiles are defined — this provides minimal enforcement.
  # Consider adding profiles or disabling if not needed.
  security.apparmor = {
    enable = true;
    packages = with pkgs; [
      apparmor-utils
      apparmor-profiles
    ];
  };

  services.fail2ban.enable = true;

  security.sudo.execWheelOnly = true;

  environment.systemPackages = with pkgs; [
    vulnix
    seahorse
  ];
}
