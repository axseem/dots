{...}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
      auto-optimise-store = true;
    };

    optimise.automatic = true;

    gc.automatic = true;
  };

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [
    (final: prev: {
      croc = prev.croc.overrideAttrs (old: {
        src = old.src.override {
          hash = "sha256-+KG1PHUymeoAj92UAn/sitQF6xC1xwl+cdisxy2ZtPs=";
        };
      });
    })
  ];
}
