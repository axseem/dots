{pkgs, ...}: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      ${pkgs.nix-your-shell}/bin/nix-your-shell fish | source
    '';
  };

  xdg.configFile."fish/conf.d".source = ../../../../config/fish/conf.d;
  xdg.configFile."fish/functions".source = ../../../../config/fish/functions;

  home.packages = [pkgs.nix-your-shell];
}
