{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    reaper
    carla

    drumgizmo
    geonkick

    # Effects
    dragonfly-reverb
    lsp-plugins

    # Synth
    vital
    odin2
  ];
}
