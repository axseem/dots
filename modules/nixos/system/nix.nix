{...}: {
  nix = {
    settings = {
      auto-optimise-store = true;
    };

    gc = {
      dates = "weekly";
    };
  };
}
