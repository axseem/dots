{
  lib,
  username,
  ...
}: let
  lanInterface = "wlp99s0";
  lanSubnet = "10.0.0.0/24";
  sshPort = 22;
in {
  # TODO(ssh-lan): Gate this service/rule on the trusted home NetworkManager
  # profile. Interface plus subnet do not distinguish home Wi-Fi from another
  # network that happens to use the same private subnet.

  # SSH is deliberately limited to the local IPv4 Wi-Fi subnet. In addition
  # to the firewall restriction, sshd independently rejects users connecting
  # from outside this subnet.
  services.openssh = {
    enable = true;
    openFirewall = false;
    authorizedKeysFiles = lib.mkForce ["/etc/ssh/authorized_keys.d/%u"];
    listenAddresses = [
      {
        addr = "0.0.0.0";
        port = sshPort;
      }
    ];
    settings = {
      AddressFamily = "inet";
      AllowUsers = ["${username}@${lanSubnet}"];
      AuthenticationMethods = "publickey";
      DisableForwarding = true;
      KbdInteractiveAuthentication = false;
      MaxAuthTries = 3;
      PasswordAuthentication = false;
      PermitEmptyPasswords = false;
      PermitRootLogin = "no";
      PermitUserEnvironment = false;
      PubkeyAuthentication = true;
      X11Forwarding = false;
    };
  };

  # Termux Ed25519 key, fingerprint:
  # SHA256:pbGwdoV0fdk/4q7AKB7wNRey6dr8z4Spq8iLPOABVzM
  # TODO(ssh-lan): Replace this key and fingerprint when the Termux key is
  # rotated or the phone is replaced.
  users.users.${username}.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHZ9tlmbyGtLh4FhM7zN0EB7tzan5VNeD5sTByHywk4Y u0_a225@localhost"
  ];

  # Do not use allowedTCPPorts here: that would expose SSH to every IPv4 and
  # IPv6 source. The NixOS iptables firewall inserts this before its final
  # reject rule. Replies are covered by its established-connection rule.
  networking.firewall.extraCommands = ''
    iptables -w -A nixos-fw -i ${lanInterface} -s ${lanSubnet} -p tcp --dport ${toString sshPort} -m conntrack --ctstate NEW -j nixos-fw-accept
  '';
}
