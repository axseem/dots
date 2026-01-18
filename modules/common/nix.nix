{...}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      trusted-users = ["root" "@wheel"];
    };

    optimise.automatic = true;

    gc = {
      automatic = true;
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;
}
