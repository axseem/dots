{pkgs, ...}: {
  nix = {
    settings = {
      experimental-features = ["nix-command" "flakes"];
      # @wheel is the NixOS admin group; macOS admins are in @admin.
      trusted-users =
        ["root"]
        ++ (
          if pkgs.stdenv.isDarwin
          then ["@admin"]
          else ["@wheel"]
        );
      auto-optimise-store = true;
    };

    optimise.automatic = true;

    gc.automatic = true;
  };

  nixpkgs.config.allowUnfree = true;
}
