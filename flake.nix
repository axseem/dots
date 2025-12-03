{
  description = "axseem's NixOS Config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nvim = {
      url = "path:./config/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dirmd = {
      url = "github:axseem/dirmd";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    flake-utils,
    ...
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      import ./nix/dev.nix {
        pkgs = nixpkgs.legacyPackages.${system};
        inherit inputs;
      })
    // {
      nixosModules = {
        # Desktop
        hyprland = import ./modules/desktop/hyprland.nix;
        display-manager = import ./modules/desktop/display-manager.nix;
        
        # Hardware
        audio = import ./modules/hardware/audio.nix;
        bluetooth = import ./modules/hardware/bluetooth.nix;
        graphics = import ./modules/hardware/graphics.nix;
        input = import ./modules/hardware/input.nix;
        power = import ./modules/hardware/power.nix;

        # Security
        hardening = import ./modules/security/hardening.nix;

        # Services
        system-services = import ./modules/services/system.nix;
        virtualization = import ./modules/services/virtualization.nix;

        # System
        boot = import ./modules/system/boot.nix;
        fonts = import ./modules/system/fonts.nix;
        locale = import ./modules/system/locale.nix;
        networking = import ./modules/system/networking.nix;
        nix = import ./modules/system/nix.nix;
        
        # Packages
        dev-tools = import ./modules/system/dev-tools.nix;
        audio-production = import ./modules/system/audio-production.nix;
      };

      homeManagerModules = {
        fish = import ./modules/home/fish;
        vscode = import ./modules/home/vscode;
        git = import ./modules/home/git.nix;
        ui = import ./modules/home/ui.nix;
        xdg = import ./modules/home/xdg.nix;
        
        # Package Groups
        cli = import ./modules/home/cli.nix;
        media = import ./modules/home/media.nix;
        apps = import ./modules/home/apps.nix;
        desktop-utils = import ./modules/home/desktop-utils.nix;
      };

      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          ./hosts/laptop/configuration.nix
        ];
      };
    };
}
