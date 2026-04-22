{
  inputs,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix

    ../../../modules/common/nix.nix
    ../../../modules/nixos/system/nix.nix
    ../../../modules/nixos/services/garden/module.nix
    ../../../modules/nixos/services/nebula/module.nix
  ];

  networking.hostName = "axsmsrvr";
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [80 443];
  networking.firewall.allowedUDPPorts = [4242];

  services.nebula-mesh = {
    enable = true;
    role = "lighthouse";
    meshIp = "10.10.0.1";
    meshHosts = {
      "mesh-axsmsrvr" = "10.10.0.1";
      "mesh-ideapad" = "10.10.0.2";
      "mesh-phone" = "10.10.0.3";
    };
  };

  services.openssh = {
    enable = true;
    passwordAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  security.sudo.wheelNeedsPassword = false;
  users.users = {
    root.hashedPassword = lib.mkDefault "!";
    axseem = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFgHsajKdoFryzgVP5H7wL5BoKBKX6WjSBYiGZNJuM2F max@axseem.me"
      ];
    };
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "max@axseem.me";
  };

  services.garden = {
    enable = true;
    domain = "axseem.me";
    webhookSecretPath = "/var/secrets/garden-webhook-secret";
    cachePath = "/var/cache/garden-build";
    sitePath = "/var/www/garden";
    repoUrl = "https://codeberg.org/axseem/garden";
  };

  services.nginx = {
    enable = true;
    serverTokens = false;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  environment.systemPackages = with pkgs; [
    htop
    tmux
    git
    curl
    wget
    tree
  ];

  system.stateVersion = "24.11";
}
