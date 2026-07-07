{
  pkgs,
  config,
  inputs,
  ...
}: let
  # Shared model limits for all local LLM providers
  modelLimit = {
    context = 131072;
    output = 131072;
  };

  # Notifier plugin config — extracted here to keep the main settings block clean
  notifierConfig = let
    # All "loud" events use the same alert profile; quiet events silence everything.
    loud = {
      sound = true;
      notification = true;
      bell = true;
    };
    quiet = {
      sound = false;
      notification = false;
      bell = false;
    };
  in {
    sound = true;
    notification = true;
    bell = true;
    timeout = 5;
    showProjectName = true;
    suppressWhenFocused = true;
    events = {
      permission = loud;
      complete = loud;
      error = loud;
      question = loud;
      subagent_complete = quiet;
      user_cancelled = quiet;
    };
  };

  # Custom tools derivation: bundles TypeScript tools with their zod dependency
  tools =
    pkgs.runCommandLocal "opencode-tools" {
      zodSrc = pkgs.fetchurl {
        url = "https://registry.npmjs.org/zod/-/zod-4.1.8.tgz";
        hash = "sha256-GT46M9xm1nnVIsQOalE4eIZG08alA50MXCs77eg7ZjU=";
      };
    } ''
      mkdir -p $out/node_modules/zod
      tar -xzf $zodSrc -C $out/node_modules/zod --strip-components=1
      cp ${./tools/web_search.ts} $out/web_search.ts
      cp ${./tools/extract_pdf.ts} $out/extract_pdf.ts
    '';

  # OpenCode reference docs: extracted from the project source for offline agent search.
  # Structure: refs/opencode/*.mdx + refs/MANIFEST.md (auto-generated index).
  # Updated via `nix flake lock --update-input opencode-source`.
  opencodeRefs = pkgs.runCommandLocal "opencode-refs" {} ''
      mkdir -p $out/opencode
      cp ${inputs.opencode-source}/packages/web/src/content/docs/*.mdx $out/opencode/

      # Auto-generate MANIFEST.md — agents read this first (< 50 tokens) to
      # decide what's available locally before reaching for the network.
      cat > $out/MANIFEST.md << MANEOF
    # Local Reference Library

    This directory contains local plain-text copies of documentation and reference
    material. Agents MUST check here FIRST before using webfetch/websearch.

    ## opencode/ — OpenCode CLI documentation
    $(ls $out/opencode/*.mdx | wc -l | tr -d ' ') files
    Topics: $(ls $out/opencode/*.mdx | sed 's|.*/||; s/\.mdx$//' | sort | tr '\n' ', ' | sed 's/, $//')

    Search: grep -rn "your pattern" ~/.config/opencode/refs/opencode/
    MANEOF
  '';
in {
  programs.opencode = {
    enable = true;
    settings = {
      permission = {
        # --- Built-in tools ---
        read = "allow";
        glob = "allow";
        grep = "allow";
        webfetch = "allow";
        lsp = "allow";
        todowrite = "allow";
        edit = "ask";
        bash = "ask";
        task = "ask";
        skill = "ask";

        # --- Built-in tools we disable ---
        websearch = "deny"; # Exa/Parallel only, not configured; use web_search

        # --- Custom tools ---
        web_search = "allow";
        extract_pdf = "allow";
      };
      plugin = ["@mohak34/opencode-notifier@latest"];
      provider = {
        local = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (local)";
          options.baseURL = "http://localhost:8080/v1";
          models.local-model = {
            name = "local model";
            limit = modelLimit;
          };
        };
        LAN = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (LAN)";
          options.baseURL = "http://10.0.0.11:8080/v1";
          models.LAN-model = {
            name = "LAN model";
            limit = modelLimit;
          };
        };
      };
      agent = {
        explore.disable = true;
        general.disable = true;
        build.disable = true;
        plan.disable = true;
      };
    };
    agents = ./agents;
    tools = "${tools}";
  };

  xdg.configFile = {
    "opencode/tools" = {
      source = "${tools}";
      recursive = true;
    };
    "opencode/AGENTS.md".source = ./AGENTS.md;
    "opencode/skills" = {
      source = ./skills;
      recursive = true;
    };
    "opencode/opencode-notifier.json".text = builtins.toJSON notifierConfig;
    "opencode/refs" = {
      source = "${opencodeRefs}";
      recursive = true;
    };
  };
}
