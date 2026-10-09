{
  lib,
  pkgs,
  ...
}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    # The socket lives in $XDG_RUNTIME_DIR; the launcher and the save timer
    # follow the same location (see tmux-session.nix and tmux-session.lua).
    secureSocket = true;
    # Persistence is driven by the tmux-session launcher (restore on start)
    # and a systemd timer (save), not by continuum.
    plugins = [pkgs.tmuxPlugins.resurrect];
    extraConfig = ''
      set -g prefix C-b
      set -g base-index 1
      set -g renumber-windows on
      set -g allow-passthrough on
      set -g extended-keys always
      set -g extended-keys-format csi-u
      # Windows are named by the launcher (s1, s2, ...); programs must not
      # rename them and the launcher must not rename them either.
      set -g automatic-rename off
      set -g set-titles on
      set -g set-titles-string '#W'
      # The phone attaches to the same windows with a smaller client; size a
      # window to the clients actually displaying it so the phone gets a
      # readable width and the laptop is not dragged down by it either.
      set -g aggressive-resize on
      set -g window-size smallest
      set -g status off
      set -g status-style "bg=black,fg=default"
      set -g window-status-style "bg=black,fg=default"
      set -g window-status-current-style "bg=black,fg=default"
      set -g pane-border-style "bg=default,fg=black"
      set -g pane-active-border-style "bg=default,fg=black"

      set -gu status-left
      set -gu status-right
      set -gu window-status-format
      set -gu window-status-current-format
      unbind-key -q -T root C-b
      bind-key -T prefix C-b send-prefix
      bind-key -T prefix b if-shell -F '#{==:#{status},on}' 'set -g status off' 'set -g status on'
    '';
  };

  programs.fish.interactiveShellInit = lib.mkAfter (builtins.readFile ../../../config/fish/tmux-autostart.fish);
}
