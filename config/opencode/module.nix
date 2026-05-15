{
  pkgs,
  config,
  ...
}: let
  tools =
    pkgs.runCommand "opencode-tools" {
      zodSrc = pkgs.fetchurl {
        url = "https://registry.npmjs.org/zod/-/zod-4.1.8.tgz";
        hash = "sha256-GT46M9xm1nnVIsQOalE4eIZG08alA50MXCs77eg7ZjU=";
      };
    } ''
      mkdir -p $out/node_modules/zod
      tar -xzf $zodSrc -C $out/node_modules/zod --strip-components=1
      cp ${./tools/read-pdf.ts} $out/read-pdf.ts
      cp ${./tools/search-web.ts} $out/search-web.ts
    '';
in {
  programs.opencode = {
    enable = true;
    settings = {
      permission = {
        read = "allow";
        glob = "allow";
        grep = "allow";
        list = "allow";
        webfetch = "allow";
        websearch = "allow";
        search-web = "allow";
        read-pdf = "allow";
        codesearch = "allow";
        lsp = "allow";
        todoread = "allow";
        edit = "ask";
        bash = "ask";
        todowrite = "ask";
        task = "ask";
        skill = "ask";
      };
      provider = {
        local = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (local)";
          options.baseURL = "http://localhost:8080/v1";
          models.local-model = {
            name = "local model";
            limit = {
              context = 131072;
              output = 98304;
            };
          };
        };
        LAN = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (LAN)";
          options.baseURL = "http://10.0.0.8:8080/v1";
          models.LAN-model = {
            name = "LAN model";
            limit = {
              context = 131072;
              output = 98304;
            };
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
  };
}
