{ pkgs, ... }: {
  home.packages = with pkgs; [
    # File Management
    file-roller
    nemo
    kdePackages.dolphin
    nautilus

    # Utilities
    gnome-calculator
    qalculate-gtk
    
    # System / Desktop Integration
    (rofi.override { plugins = [ rofi-emoji rofi-calc ]; })
    rofi-bluetooth
    networkmanager_dmenu
    cliphist
    pavucontrol
    gcr
    seahorse
  ];
}
