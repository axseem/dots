{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.garden;
  webhookHandler = pkgs.writeShellScriptBin "garden-webhook-handler" (builtins.readFile ./webhook-handler.sh);
in {
  options.services.garden = {
    enable = mkEnableOption "garden static site with auto-deploy webhook";

    domain = mkOption {
      type = types.str;
      description = "Domain to serve the garden site on.";
      example = "axseem.me";
    };

    webhookSecretPath = mkOption {
      type = types.str;
      description = "Path to file containing the webhook secret for HMAC verification.";
      example = "/var/secrets/garden/webhook-secret";
    };

    cachePath = mkOption {
      type = types.str;
      default = "/var/cache/garden-build";
      description = "Path for build cache and git repository.";
    };

    sitePath = mkOption {
      type = types.str;
      default = "/var/www/garden";
      description = "Path where the built site will be served from.";
    };

    repoUrl = mkOption {
      type = types.str;
      description = "Git repository URL to clone/pull from.";
      example = "https://codeberg.org/axseem/garden";
    };

    webhookPort = mkOption {
      type = types.port;
      default = 9000;
      description = "Port for webhook receiver.";
    };

    branch = mkOption {
      type = types.str;
      default = "main";
      description = "Git branch to track for deployments.";
      example = "main";
    };
  };

  config = mkIf cfg.enable {
    services.nginx.enable = mkDefault true;

    users.users.garden = {
      isSystemUser = true;
      group = "garden";
      home = cfg.cachePath;
      shell = pkgs.bash;
    };
    users.groups.garden = {};

    systemd.tmpfiles.rules = [
      "d ${cfg.cachePath} 0755 garden garden -"
      "d ${cfg.sitePath} 0755 garden nginx -"
      "d /var/secrets/garden 0750 garden garden -"
    ];

    systemd.services.garden-webhook = {
      description = "Garden Webhook Receiver";
      after = ["network.target" "nix-daemon.service"];
      requires = ["nix-daemon.service"];
      wantedBy = ["multi-user.target"];

      serviceConfig = {
        Type = "simple";
        User = "garden";
        Group = "garden";
        ExecStart = "${pkgs.python3}/bin/python3 ${./webhook-server.py} --port ${toString cfg.webhookPort} --secret-path ${cfg.webhookSecretPath} --handler ${webhookHandler}/bin/garden-webhook-handler --cache-path ${cfg.cachePath} --site-path ${cfg.sitePath} --repo-url ${cfg.repoUrl} --branch ${cfg.branch}";
        Restart = "always";
        RestartSec = "5s";
        ProtectSystem = "strict";
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [cfg.cachePath cfg.sitePath];
        ReadOnlyPaths = [cfg.webhookSecretPath];
      };
    };

    systemd.services.garden-initial-build = {
      description = "Initial Garden Site Build";
      after = ["network.target" "nix-daemon.service"];
      requires = ["nix-daemon.service"];
      wantedBy = ["multi-user.target"];
      before = ["nginx.service"];

      serviceConfig = {
        Type = "oneshot";
        User = "garden";
        Group = "garden";
        ExecStart = "${webhookHandler}/bin/garden-webhook-handler ${cfg.cachePath} ${cfg.sitePath} ${cfg.repoUrl} ${cfg.branch}";
        RemainAfterExit = true;
        ProtectSystem = "strict";
        PrivateTmp = true;
        NoNewPrivileges = true;
        ReadWritePaths = [cfg.cachePath cfg.sitePath];
      };
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      root = "${cfg.sitePath}/current";
      locations."/" = {
        tryFiles = "$uri $uri/ =404";
      };
      locations."/hooks/garden" = {
        proxyPass = "http://127.0.0.1:${toString cfg.webhookPort}";
        extraConfig = ''
          allow 185.236.41.0/24;
          deny all;
        '';
      };
      extraConfig = ''
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
      '';
    };
  };
}
