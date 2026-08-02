{pkgs, ...}: {
  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --time --time-format '%I:%M %p | %a • %h | %F' --cmd 'start-hyprland'";
      user = "greeter";
    };
  };

  environment.systemPackages = [pkgs.tuigreet];

  # Unlock the user's "login" keyring at greetd login: greetd's PAM chain
  # includes the `login` service, so enabling the keyring module there makes
  # pam_gnome_keyring auto-unlock with the login password (the daemon itself
  # is started by home-manager's services.gnome-keyring).
  security.pam.services.login.enableGnomeKeyring = true;
}
