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
          hash = "sha256-u262LwHUL6+rPE7nzIda7W5dAXaikQ/cKwtUEIbcbH0=";
        };
      });
    })
  ];
}
