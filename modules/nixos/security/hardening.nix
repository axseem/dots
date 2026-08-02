{pkgs, ...}: {
  users.users.root.hashedPassword = "!";

  # NOTE: AppArmor is enabled with default profiles only.
  # No custom profiles are defined — this provides minimal enforcement.
  # Add profiles via security.apparmor.profiles (e.g. for searx) if desired.
  security.apparmor = {
    enable = true;
    packages = with pkgs; [
      apparmor-utils
      apparmor-profiles
    ];
  };

  services.fail2ban.enable = true;

  # Cheap kernel hardening. No rp_filter tweaks: strict filtering breaks
  # multi-homed/VPN routing (proton0). No userns restriction: flatpak and
  # rootless podman need unprivileged namespaces.
  boot.kernel.sysctl = {
    "kernel.dmesg_restrict" = 1;
    "kernel.kptr_restrict" = 1;
    "kernel.yama.ptrace_scope" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv6.conf.all.accept_redirects" = 0;
    "net.ipv6.conf.default.accept_redirects" = 0;
  };

  security.sudo.execWheelOnly = true;

  # users.mutableUsers = false is intentionally not set: the user has no
  # hashedPassword in the config, so locking the account store would break
  # password auth/sudo on the next rebuild. Add a hash first if desired.

  environment.systemPackages = with pkgs; [
    vulnix
    seahorse
  ];
}
