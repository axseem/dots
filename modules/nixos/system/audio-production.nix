{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    reaper # DAW

    # REMOVED: Sfizz (It is currently broken on NixOS Unstable)
    # ADDED: Carla (Has built-in SFZ support)
    carla

    drumgizmo # Drums
    geonkick # Percussion

    # Effects
    dragonfly-reverb
    lsp-plugins

    # Synth
    vital
    #surge
    odin2
  ];
}
