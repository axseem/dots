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
        # One retry per second; retry-max-time remains the hard deadline.
        pollCount = opts.startupWaitSeconds;
      in {
        sockets."${proxyService}" = {
          wantedBy = ["sockets.target"];
          listenStreams = ["${opts.bindAddress}:${toString opts.publicPort}"];
          socketConfig.Accept = false;
        };

        services."${proxyService}" = {
          requires = ["${opts.service}.service"];
          after = ["${opts.service}.service"];

          serviceConfig =
            {
              # Block until the upstream accepts requests, with a hard cap.
              ExecStartPre = "${pkgs.curl}/bin/curl --fail --silent --show-error --output /dev/null --retry ${toString pollCount} --retry-all-errors --retry-delay 1 --retry-max-time ${toString opts.startupWaitSeconds} http://${opts.bindAddress}:${toString opts.internalPort}${opts.healthCheckPath}";
              ExecStart = "${config.systemd.package}/lib/systemd/systemd-socket-proxyd ${opts.bindAddress}:${toString opts.internalPort}";
              # The proxy needs no privileges: it accepts via the socket fd
              # and connects to the loopback upstream only.
              DynamicUser = true;
              NoNewPrivileges = true;
              ProtectSystem = "strict";
              ProtectHome = true;
              PrivateTmp = true;
              PrivateDevices = true;
              ProtectKernelTunables = true;
              ProtectKernelModules = true;
              ProtectKernelLogs = true;
              ProtectControlGroups = true;
              ProtectClock = true;
              ProtectHostname = true;
              ProtectProc = "invisible";
              RestrictSUIDSGID = true;
              RestrictNamespaces = true;
              RestrictAddressFamilies = ["AF_INET" "AF_INET6" "AF_UNIX"];
              RestrictRealtime = true;
              SystemCallFilter = ["@system-service" "~@privileged @resources"];
              LockPersonality = true;
              CapabilityBoundingSet = [""];
              UMask = "0077";
              # Loopback backend only: deny all other network egress.
              IPAddressDeny = "any";
              IPAddressAllow = ["127.0.0.1" "::1"];
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
