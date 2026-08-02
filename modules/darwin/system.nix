{
  pkgs,
  username,
  ...
}: {
  environment.shells = [pkgs.fish];
  # nix-darwin only applies user attributes for users listed in knownUsers.
  users.knownUsers = [username];
  users.users.${username} = {
    uid = 501; # standard macOS primary-user uid
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  nix.gc.interval = {
    Weekday = 0;
    Hour = 2;
    Minute = 0;
  };

  system.defaults.universalaccess.reduceTransparency = true;
}
