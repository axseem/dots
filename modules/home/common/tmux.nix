{lib, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
    extraConfig = ''
      set -g prefix C-b
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

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if status is-interactive; and not set -q TMUX; and not set -q TMUX_AUTOSTART_DISABLED; and command -q tmux
      exec tmux new-session -A -s main
    end
  '';
}
