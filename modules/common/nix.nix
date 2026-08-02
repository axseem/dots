{
  pkgs,
  lib,
  ...
}: {
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

    # darwin schedules via nix.gc.interval (see darwin/system.nix).
    gc =
      {
        automatic = true;
      }
      // lib.optionalAttrs (!pkgs.stdenv.isDarwin) {
        dates = "weekly";
        options = "--delete-older-than 14d";
      };
  };

  nixpkgs.config.allowUnfree = true;
}
