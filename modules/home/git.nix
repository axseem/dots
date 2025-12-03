{ pkgs, ... }: {
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      init.defaultBranch = "main";
    };
  };
}
