{
  pkgs,
  username,
  ...
}: {
  users.users.${username} = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = ["wheel" "video" "dialout" "networkmanager" "docker" "adbusers" "audio"];
  };

  programs.nix-ld.enable = true;
}
