{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.searxng-local;
in {
  options.services.searxng-local = {
    enable = mkEnableOption "Local SearXNG search engine with lazy socket activation";
  };

  config = mkIf cfg.enable {
    services.searx = {
      enable = true;
      redisCreateLocally = true;
      settings = {
        use_default_settings = true;
        server = {
          bind_address = "127.0.0.1";
          port = 8889;
          secret_key = "local-only-not-sensitive";
          limiter = false;
          image_proxy = false;
          base_url = false;
          method = "GET";
        };
        general = {
          debug = false;
          instance_name = "Local SearXNG";
          enable_metrics = false;
        };
        search = {
          safe_search = 0;
          autocomplete = "";
          default_lang = "auto";
          formats = ["html" "json"];
          max_results = 10;
        };
        ui = {
          infinite_scroll = false;
          default_theme = "simple";
        };
        outgoing = {
          request_timeout = 10;
          max_request_timeout = 15;
        };
        # Enable research-useful engines that are disabled by default.
        # Mainstream engines (google, brave, duckduckgo, startpage, qwant, etc.)
        # come in via use_default_settings = true.
        # hash_plugin is already active by default -> content-hash dedup is on.
        engines = [
          {
            name = "crossref";
            disabled = false;
          } # academic metadata
          {
            name = "gitlab";
            disabled = false;
          } # code hosting
          {
            name = "npm";
            disabled = false;
          } # JS packages
          {
            name = "crates.io";
            disabled = false;
          } # Rust packages
          {
            name = "mojeek";
            disabled = false;
          } # independent web search
          {
            name = "nixos wiki";
            disabled = false;
          } # NixOS reference
        ];
      };
    };

    # Lazy socket activation: zero resources when idle, auto-starts on any request to 8888
    services.lazy-socket.searxng = {
      enable = true;
      publicPort = 8888;
      internalPort = 8889;
      service = "searx";
      idleTimeout = 300;
      startupWaitSeconds = 15;
      healthCheckPath = "/";
    };

    environment.systemPackages = [
      # Manual CLI for the local instance (`sxng query "..."`); the service
      # itself runs without it.
      (pkgs.buildGoModule {
        pname = "sxng";
        version = "0.1.0";
        src = ./cli;
        # stdlib-only: nothing to fetch, build stays hermetic. If an external
        # dependency is added, run `go mod vendor` and set vendorHash here.
        vendorHash = null;
      })
    ];
  };
}
