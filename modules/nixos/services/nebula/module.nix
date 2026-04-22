{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.nebula-mesh;
  nebulaPkg = pkgs.nebula;
  lighthouseMeshIp = "10.10.0.1";
in {
  options.services.nebula-mesh = {
    enable = mkEnableOption "nebula mesh VPN";

    role = mkOption {
      type = types.enum ["lighthouse" "node"];
      description = "Role in the Nebula mesh network.";
    };

    meshIp = mkOption {
      type = types.str;
      description = "IP address within the mesh network.";
      example = "10.10.0.1";
    };

    meshCidr = mkOption {
      type = types.int;
      default = 24;
      description = "CIDR suffix for the mesh network.";
    };

    lighthouseHost = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Public hostname or IP of the lighthouse (for nodes only).";
      example = "axseem.me";
    };

    lighthousePort = mkOption {
      type = types.port;
      default = 4242;
      description = "UDP port for Nebula communication.";
    };

    certPath = mkOption {
      type = types.str;
      default = "/var/secrets/nebula/host.crt";
      description = "Path to host certificate.";
    };

    keyPath = mkOption {
      type = types.str;
      default = "/var/secrets/nebula/host.key";
      description = "Path to host private key.";
    };

    caPath = mkOption {
      type = types.str;
      default = "/var/secrets/nebula/ca.crt";
      description = "Path to CA certificate.";
    };

    meshHosts = mkOption {
      type = types.attrsOf types.str;
      default = {};
      description = "Map of hostname to mesh IP for /etc/hosts entries.";
      example = {"mesh-axsmsrvr" = "10.10.0.1";};
    };

    firewallAllowFromMesh = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Ports to allow from mesh network.";
      example = ["22"];
    };
  };

  config = mkIf cfg.enable {
    systemd.tmpfiles.rules = [
      "d /var/secrets/nebula 0700 nebula-nebula-mesh nebula-nebula-mesh -"
    ];

    networking.extraHosts = concatStringsSep "\n" (
      mapAttrsToList (hostname: ip: "${ip} ${hostname}") cfg.meshHosts
    );

    services.nebula.networks.nebula-mesh = {
      enable = true;
      package = nebulaPkg;

      ca = cfg.caPath;
      cert = cfg.certPath;
      key = cfg.keyPath;

      isLighthouse = cfg.role == "lighthouse";

      lighthouses = mkIf (cfg.role == "node") [lighthouseMeshIp];

      staticHostMap = mkIf (cfg.role == "node" && cfg.lighthouseHost != null) {
        "${lighthouseMeshIp}" = ["${cfg.lighthouseHost}:${toString cfg.lighthousePort}"];
      };

      listen = {
        host = "0.0.0.0";
        port = cfg.lighthousePort;
      };

      tun.device = "nebula0";

      firewall = {
        inbound = [
          {
            port = "any";
            proto = "any";
            host = "10.10.0.0/${toString cfg.meshCidr}";
          }
        ];
        outbound = [
          {
            port = "any";
            proto = "any";
            host = "any";
          }
        ];
      };

      settings = {
        punchy = {
          punch = cfg.role == "node";
        };

        relay = {
          use_relays = false;
        };

        cipher = "aes";
      };
    };

    networking.firewall.allowedUDPPorts = [cfg.lighthousePort];

    networking.firewall.extraCommands = mkIf (cfg.firewallAllowFromMesh != []) ''
      iptables -N nebula-mesh || true
      iptables -F nebula-mesh
      ${concatMapStrings (port: ''
          iptables -A nebula-mesh -s 10.10.0.0/${toString cfg.meshCidr} -p tcp --dport ${port} -j ACCEPT
        '')
        cfg.firewallAllowFromMesh}
      iptables -A nebula-mesh -j RETURN
      iptables -I nixos-fw -i nebula0 -j nebula-mesh
    '';

    networking.firewall.extraStopCommands = ''
      iptables -D nixos-fw -i nebula0 -j nebula-mesh 2>/dev/null || true
      iptables -F nebula-mesh 2>/dev/null || true
      iptables -X nebula-mesh 2>/dev/null || true
    '';
  };
}
