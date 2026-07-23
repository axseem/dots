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
}
