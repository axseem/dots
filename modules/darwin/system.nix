{pkgs, username, ...}: {
  # Set fish as default shell
  environment.shells = [pkgs.fish];
  users.users.${username}.shell = pkgs.fish;
  programs.fish.enable = true;

  system.defaults = {
    universalaccess = {
      reduceTransparency = true;
    };
  };
}
