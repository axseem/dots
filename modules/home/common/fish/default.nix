{
  programs = {
    fish.enable = true;
    nix-your-shell = {
      enable = true;
      enableFishIntegration = true;
    };
  };

  xdg.configFile."fish/conf.d".source = ../../../../config/fish/conf.d;
}
