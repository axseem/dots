{
  pkgs,
  username,
  ...
}: {
  environment.shells = [pkgs.fish];
  users.users.${username}.shell = pkgs.fish;
  programs.fish.enable = true;

  nix.gc.interval = {
    Weekday = 0;
    Hour = 2;
    Minute = 0;
  };

  system.defaults.universalaccess.reduceTransparency = true;
}
