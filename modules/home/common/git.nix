{
  pkgs,
  username,
  ...
}: {
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      init.defaultBranch = "main";
      user = {
        name = username;
        email = "max@axseem.me";
      };
    };
  };
}
