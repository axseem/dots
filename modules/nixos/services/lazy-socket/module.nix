{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.lazy-socket;

  # Filter to only enabled services; disabled entries are inert.
  enabled = filterAttrs (_: v: v.enable) cfg;

  # Extract (bindAddress, port) pairs to detect collisions.
  publicSockets = mapAttrsToList (_: v: "${v.bindAddress}:${toString v.publicPort}") enabled;
  internalSockets = mapAttrsToList (_: v: "${v.bindAddress}:${toString v.internalPort}") enabled;

  # A service's public socket must not equal another service's internal
  # socket on the same bind address — that would silently route traffic
  # to the wrong backend.
  hasConflict = set: length set != length (lists.unique set);
in {
  options.services.lazy-socket = mkOption {
    type = types.attrsOf (types.submodule {
      options = {
        enable = mkEnableOption "lazy socket activation for this service";

        publicPort = mkOption {
          type = types.port;
          description = "Port that external clients connect to (systemd listens here).";
        };

        internalPort = mkOption {
          type = types.port;
          description = "Port the actual service binds to internally.";
        };

        bindAddress = mkOption {
          type = types.str;
          default = "127.0.0.1";
          description = "Address to listen on.";
        };

        idleTimeout = mkOption {
          type = types.int;
          default = 300;
          description = "Seconds of runtime before auto-stopping the service. 0 = never auto-stop.";
        };

        service = mkOption {
          type = types.str;
          description = "Name of the systemd service to activate (e.g. \"searx\").";
        };

        startupWaitSeconds = mkOption {
          type = types.int;
          default = 15;
          description = "Max seconds to wait for the service to become ready.";
        };

        healthCheckPath = mkOption {
          type = types.str;
          default = "/";
          description = "HTTP path to check for service readiness.";
        };
      };
    });
    default = {};
    description = "Lazy socket activation proxy for any HTTP service.";
  };

  config = mkIf (enabled != {}) {
    assertions = [
      {
        assertion = !(hasConflict publicSockets);
        message = "lazy-socket: publicPort+bindAddress must be unique across services. Got: ${concatStringsSep ", " publicSockets}";
      }
      {
        assertion = !(hasConflict internalSockets);
        message = "lazy-socket: internalPort+bindAddress must be unique across services. Got: ${concatStringsSep ", " internalSockets}";
      }
    ];

    systemd = foldAttrs (acc: x: acc // x) {} (mapAttrsToList (name: opts: let
        proxyService = "lazy-socket-${name}";
        # 2 retries per second × startupWaitSeconds = total poll count
        pollCount = opts.startupWaitSeconds * 2;
      in {
        sockets."${proxyService}" = {
          wantedBy = ["sockets.target"];
          listenStreams = ["${opts.bindAddress}:${toString opts.publicPort}"];
          socketConfig.Accept = false;
        };

        services."${proxyService}" = {
          requires = ["${opts.service}.service"];
          after = ["${opts.service}.service"];

          # Block the proxy until the upstream is actually accepting
          # connections. Hard cap on iterations to avoid infinite waits
          # if the service fails to start.
          preStart = ''
            for i in $(seq 1 ${toString pollCount}); do
              ${pkgs.curl}/bin/curl -sf \
                http://${opts.bindAddress}:${toString opts.internalPort}${opts.healthCheckPath} \
                -o /dev/null 2>/dev/null && break
              sleep 0.5
            done
          '';

          serviceConfig =
            {
              ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${opts.bindAddress}:${toString opts.internalPort}";
            }
            // optionalAttrs (opts.idleTimeout > 0) {
              RuntimeMaxSec = opts.idleTimeout;
            };
        };

        # Prevent the actual service from starting at boot, and set its idle timeout
        services."${opts.service}" =
          {
            wantedBy = mkForce [];
          }
          // optionalAttrs (opts.idleTimeout > 0) {
            serviceConfig.RuntimeMaxSec = opts.idleTimeout;
          };
      })
      enabled);
  };
}
