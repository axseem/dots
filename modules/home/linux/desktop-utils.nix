{pkgs, ...}: let
  rofi-combi-calc = pkgs.rofi-unwrapped.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./rofi-combi-calc.patch];
  });

  # rofi-calc normally renders its live result in a message widget. Rofi's
  # combi mode does not forward mode messages, so expose the result as a row.
  rofi-calc-combi = pkgs.rofi-calc.overrideAttrs (old: {
    patches = (old.patches or []) ++ [./rofi-calc-combi.patch];
  });
in {
  home.packages = with pkgs; [
    # File Management
    file-roller
    nautilus

    # Utilities
    qalculate-gtk
    libqalculate
    grim
    slurp
    wl-clipboard

    # System / Desktop Integration
    (rofi.override {
      rofi-unwrapped = rofi-combi-calc;
      plugins = [rofi-emoji rofi-calc-combi];
    })
    cliphist
    networkmanager_dmenu
    pavucontrol
    gcr
  ];
}
