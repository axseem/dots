{
  pkgs,
  username,
  ...
}: {
  users.users.${username} = {
    shell = pkgs.fish;
    isNormalUser = true;
    extraGroups = ["wheel" "video" "dialout" "networkmanager" "podman" "adbusers" "audio"];
  };

  programs.nix-ld.enable = true;
}
