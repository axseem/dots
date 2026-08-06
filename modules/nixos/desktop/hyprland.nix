{pkgs, ...}: {
  programs.hyprland.enable = true;

  # TODO(glaze): remove once nixos-unstable ships the "Relax glaze dependency"
  # patch. Hyprland v0.56.1 requires glaze 7...<8 but nixpkgs e72e4f2 provides
  # glaze 8.0.0, which triggers the FetchContent fallback and fails in the
  # sandbox ("could not find git for clone of glaze").
  programs.hyprland.package = pkgs.hyprland.overrideAttrs (prev: {
    postPatch =
      (prev.postPatch or "")
      + ''
        substituteInPlace CMakeLists.txt start/CMakeLists.txt hyprpm/CMakeLists.txt \
          --replace-fail "glaze 7...<8" "glaze"
      '';
  });

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
  };

  environment.systemPackages = with pkgs; [
    # Wayland utilities
    swaynotificationcenter
    way-displays
    swaylock
    swayidle
  ];

  security.pam.services.swaylock = {};
}
