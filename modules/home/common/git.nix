{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      # user.email is host-specific; each host's home.nix sets it.
      user.name = config.home.username;
    };
  };
}
