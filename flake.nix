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
