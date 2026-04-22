{
  description = "axseem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Pinned to a known-working revision for neovim plugins.
    # Bump when nixos-unstable catches up.
    nvim-stable-pkgs.url = "github:NixOS/nixpkgs/70801e06d9730c4f1704fbd3bbf5b8e11c03a2a7";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvim = {
      url = "github:axseem/nvim";
      inputs.nixpkgs.follows = "nvim-stable-pkgs";
    };
    iosevka-unambiguous.url = "git+https://codeberg.org/axseem/iosevka-unambiguous";
    dirmd.url = "github:axseem/dirmd";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    llm-agents.url = "github:numtide/llm-agents.nix";
    llama-cpp.url = "github:ggml-org/llama.cpp";
    opencode.url = "github:anomalyco/opencode";
    voxtype = {
      url = "github:peteonrails/voxtype";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zig.url = "github:mitchellh/zig-overlay/8c20e76ce9751556dae0d1a9862ff18cda0daf1e";
    zls = {
      url = "github:zigtools/zls/f6d2476552e616e093d3713364bc0295dcd64641";
      inputs.zig-overlay.follows = "zig";
    };
  };

  outputs = {
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-darwin" "aarch64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    devFor = system:
      import ./nix/dev.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs;
      };
  in {
    formatter = forAllSystems (system: (devFor system).formatter);
    checks = forAllSystems (system: (devFor system).checks);
    devShells = forAllSystems (system: (devFor system).devShells);

    nixosModules = {
      nix = import ./modules/common/nix.nix;
      fonts = import ./modules/common/fonts.nix;
      hyprland = import ./modules/nixos/desktop/hyprland.nix;
      display-manager = import ./modules/nixos/desktop/display-manager.nix;
      audio = import ./modules/nixos/hardware/audio.nix;
      bluetooth = import ./modules/nixos/hardware/bluetooth.nix;
      graphics = import ./modules/nixos/hardware/graphics.nix;
      input = import ./modules/nixos/hardware/input.nix;
      power = import ./modules/nixos/hardware/power.nix;
      hardening = import ./modules/nixos/security/hardening.nix;
      system-services = import ./modules/nixos/services/system.nix;
      virtualization = import ./modules/nixos/services/virtualization.nix;
      flatpak = import ./modules/nixos/services/flatpak.nix;
      fonts-config = import ./modules/nixos/system/fonts.nix;
      boot = import ./modules/nixos/system/boot.nix;
      locale = import ./modules/nixos/system/locale.nix;
      networking = import ./modules/nixos/system/networking.nix;
      dev-tools = import ./modules/nixos/system/dev-tools.nix;
      audio-production = import ./modules/nixos/system/audio-production.nix;
    };

    darwinModules = {
      nix = import ./modules/common/nix.nix;
      fonts = import ./modules/common/fonts.nix;
      homebrew = import ./modules/darwin/homebrew.nix;
    };

    homeManagerModules = {
      fish = import ./modules/home/common/fish;
      vscodium = import ./modules/home/common/vscodium;
      git = import ./modules/home/common/git.nix;
      cli = import ./modules/home/common/cli.nix;
      xdg-common = import ./modules/home/common/xdg.nix;
      node = import ./modules/home/common/node.nix;
      ui = import ./modules/home/linux/ui.nix;
      xdg-linux = import ./modules/home/linux/xdg.nix;
      cli-linux = import ./modules/home/linux/cli-linux.nix;
      media = import ./modules/home/linux/media.nix;
      apps = import ./modules/home/linux/apps.nix;
      desktop-utils = import ./modules/home/linux/desktop-utils.nix;
    };

    nixosConfigurations.ideapad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = "axseem";
      };
      modules = [
        ./hosts/nixos/ideapad/configuration.nix
      ];
    };

    nixosConfigurations.ideapad-nocuda = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
        username = "axseem";
      };
      modules = [
        ./hosts/nixos/ideapad/configuration-nocuda.nix
      ];
    };

    nixosConfigurations.axsmsrvr = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./hosts/nixos/axsmsrvr/configuration.nix
        ./hosts/nixos/axsmsrvr/disko-config.nix
        inputs.disko.nixosModules.disko
      ];
    };

    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {
        inherit inputs;
        username = "max";
      };
      modules = [
        ./hosts/darwin/macbook/default.nix
      ];
    };
  };
}
