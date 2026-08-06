{lib, ...}: {
  programs.tmux = {
    enable = true;
    mouse = true;
    terminal = "tmux-256color";
    historyLimit = 100000;
  };

  programs.fish.interactiveShellInit = lib.mkAfter ''
    if status is-interactive; and not set -q TMUX; and not set -q TMUX_AUTOSTART_DISABLED; and command -q tmux
      exec tmux new-session -A -s main
    end
  '';
}
