{pkgs, ...}: let
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
    (rofi.override {plugins = [rofi-emoji rofi-calc-combi];})
    cliphist
    pavucontrol
    gcr
  ];
}
