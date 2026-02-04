{
  description = "axseem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
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
    nvim = {
      url = "github:axseem/nvim";
      inputs.nixpkgs.follows = "nvim-stable-pkgs";
    };
    dirmd.url = "github:axseem/dirmd";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    llama-cpp.url = "github:ggml-org/llama.cpp";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
  };

  outputs = {
    nixpkgs,
    nix-darwin,
    ...
  } @ inputs: let
    username = "max";
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
      # Common
      nix = import ./modules/common/nix.nix;
      fonts = import ./modules/common/fonts.nix;

      # Desktop
      hyprland = import ./modules/nixos/desktop/hyprland.nix;
      display-manager = import ./modules/nixos/desktop/display-manager.nix;

      # Hardware
      audio = import ./modules/nixos/hardware/audio.nix;
      bluetooth = import ./modules/nixos/hardware/bluetooth.nix;
      graphics = import ./modules/nixos/hardware/graphics.nix;
      input = import ./modules/nixos/hardware/input.nix;
      power = import ./modules/nixos/hardware/power.nix;

      # Security
      hardening = import ./modules/nixos/security/hardening.nix;

      # Services
      system-services = import ./modules/nixos/services/system.nix;
      virtualization = import ./modules/nixos/services/virtualization.nix;
      flatpak = import ./modules/nixos/services/flatpak.nix;

      # System
      nix-nixos = import ./modules/nixos/system/nix.nix;
      fonts-config = import ./modules/nixos/system/fonts.nix;
      boot = import ./modules/nixos/system/boot.nix;
      locale = import ./modules/nixos/system/locale.nix;
      networking = import ./modules/nixos/system/networking.nix;

      # Packages
      dev-tools = import ./modules/nixos/system/dev-tools.nix;
      audio-production = import ./modules/nixos/system/audio-production.nix;
    };

    darwinModules = {
      # Common
      nix = import ./modules/common/nix.nix;
      fonts = import ./modules/common/fonts.nix;

      # Darwin
      nix-darwin = import ./modules/darwin/nix.nix;
      homebrew = import ./modules/darwin/homebrew.nix;
    };

    homeManagerModules = {
      # Common
      fish = import ./modules/home/common/fish;
      vscode = import ./modules/home/common/vscode;
      git = import ./modules/home/common/git.nix;
      cli = import ./modules/home/common/cli.nix;
      llama = import ./modules/home/common/llama.nix;

      # Linux
      ui = import ./modules/home/linux/ui.nix;
      xdg = import ./modules/home/linux/xdg.nix;
      cli-linux = import ./modules/home/linux/cli-linux.nix;
      media = import ./modules/home/linux/media.nix;
      apps = import ./modules/home/linux/apps.nix;
      desktop-utils = import ./modules/home/linux/desktop-utils.nix;
    };

    nixosConfigurations.ideapad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {inherit inputs username;};
      modules = [
        ./hosts/nixos/ideapad/configuration.nix
      ];
    };

    darwinConfigurations.macbook = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      specialArgs = {inherit inputs username;};
      modules = [
        ./hosts/darwin/macbook/default.nix
      ];
    };
  };
}
