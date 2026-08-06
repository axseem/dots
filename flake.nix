{
  description = "axseem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim = {
      url = "github:axseem/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    iosevka-unambiguous = {
      url = "git+https://codeberg.org/axseem/iosevka-unambiguous";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    abstruct = {
      url = "git+https://codeberg.org/axseem/abstruct.git";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.blyph.url = "git+https://codeberg.org/axseem/blyph.git";
      inputs.blyph.inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode-config = {
      url = "git+https://codeberg.org/axseem/opencode-config";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    systems = ["x86_64-linux" "aarch64-darwin"];
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
      # Modules that use `inputs` are wrapped so the flake's own inputs are
      # captured in the closure; consumers need no undocumented specialArgs.
      fonts = {pkgs, ...}: import ./modules/common/fonts.nix {inherit inputs pkgs;};
      hyprland = import ./modules/nixos/desktop/hyprland.nix;
      display-manager = import ./modules/nixos/desktop/display-manager.nix;
      audio = import ./modules/nixos/hardware/audio.nix;
      bluetooth = import ./modules/nixos/hardware/bluetooth.nix;
      searxng-local = import ./modules/nixos/services/searxng/module.nix;
      lazy-socket = import ./modules/nixos/services/lazy-socket/module.nix;
      graphics = import ./modules/nixos/hardware/graphics.nix;
      power = import ./modules/nixos/hardware/power.nix;
      hardening = import ./modules/nixos/security/hardening.nix;
      system-services = import ./modules/nixos/services/system.nix;
      virtualization = import ./modules/nixos/services/virtualization.nix;
      boot = {pkgs, ...}: import ./modules/nixos/system/boot.nix {inherit inputs pkgs;};
      locale = import ./modules/nixos/system/locale.nix;
      networking = import ./modules/nixos/system/networking.nix;
      dev-tools = import ./modules/nixos/system/dev-tools.nix;
      audio-production = import ./modules/nixos/system/audio-production.nix;
    };

    darwinModules = {
      nix = import ./modules/common/nix.nix;
      fonts = {pkgs, ...}: import ./modules/common/fonts.nix {inherit inputs pkgs;};
      homebrew = import ./modules/darwin/homebrew.nix;
    };

    homeManagerModules = {
      fish = import ./modules/home/common/fish;
      tmux = import ./modules/home/common/tmux.nix;
      vscodium = import ./modules/home/common/vscodium;
      git = import ./modules/home/common/git.nix;
      cli = {pkgs, ...}: import ./modules/home/common/cli.nix {inherit inputs pkgs;};
      node = import ./modules/home/common/node.nix;
      ui = import ./modules/home/linux/ui.nix;
      xdg-linux = import ./modules/home/linux/xdg.nix;
      cli-linux = import ./modules/home/linux/cli-linux.nix;
      media = import ./modules/home/linux/media.nix;
      apps = {pkgs, ...}: import ./modules/home/linux/apps.nix {inherit inputs pkgs;};
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
