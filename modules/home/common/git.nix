{config, ...}: {
  programs.git = {
    enable = true;
    settings = {
      core.editor = "nvim";
      init.defaultBranch = "main";
      user.email = "max@axseem.me";
      user.name = config.home.username;
    };
  };
}
