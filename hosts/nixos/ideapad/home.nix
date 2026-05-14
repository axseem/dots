{
  pkgs,
  inputs,
  username,
  config,
  ...
}: {
  imports = [
    ../../../modules/home/common/fish
    ../../../modules/home/common/vscodium
    ../../../modules/home/common/git.nix
    ../../../modules/home/common/cli.nix
    ../../../modules/home/common/node.nix
    ../../../modules/home/common/xdg.nix

    ../../../modules/home/linux/ui.nix
    ../../../modules/home/linux/xdg.nix
    ../../../modules/home/linux/cli-linux.nix
    ../../../modules/home/linux/media.nix
    ../../../modules/home/linux/apps.nix
    ../../../modules/home/linux/desktop-utils.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    packages = [
      inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.pi
    ];

    sessionVariables = {
      SCREENSHOT_DIR = "${config.home.homeDirectory}/me/screenshots";
      LOCK_CMD = "swaylock -f -c 000000";
    };
  };

  # Host-specific Hyprland Configuration
  xdg.configFile."hypr/conf.d/host.conf".text = ''
    # Monitor Configuration
    monitor = eDP-1, 2880x1800@120.00Hz, 0x0, 2
    monitor = HDMI-A-2, 2560x1440@100.00Hz, 1440x0, 1

    # Host-specific variables
    $lock = swaylock -f -c 000000
  '';

  services.gnome-keyring.enable = true;

  programs.home-manager.enable = true;

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
    agents = ../../../config/opencode/agents;
    skills = ../../../config/opencode/skills;
  };
}
