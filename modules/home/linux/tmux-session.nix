{
  config,
  lib,
  pkgs,
  ...
}: let
  tmux = "${pkgs.tmux}/bin/tmux";
  session = "${pkgs.axseem.tmux-session}/bin/tmux-session";

  # secureSocket puts TMUX_TMPDIR in $XDG_RUNTIME_DIR for interactive shells
  # only; the user manager does not carry it, so without this the timer looks
  # in /tmp and misses the running server.
  socketEnvironment = lib.optionalAttrs config.programs.tmux.secureSocket {
    Environment = ["TMUX_TMPDIR=%t"];
  };
in {
  home.packages = [pkgs.axseem.tmux-session];

  # Continuum's autosave piggybacks on the status line, and this config keeps
  # the status line off, so snapshot on a timer instead. -N keeps a save from
  # starting an empty server after boot.
  systemd.user = {
    services = {
      tmux-resurrect-save = {
        Unit.Description = "Save the tmux session state";
        Service =
          {
            Type = "oneshot";
            ExecStart = "-${tmux} -N run-shell ${session} save";
          }
          // socketEnvironment;
      };

      tmux-resurrect-save-shutdown = {
        Unit.Description = "Save the tmux session state when the graphical session ends";
        Service =
          {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.coreutils}/bin/true";
            ExecStop = "-${tmux} -N run-shell ${session} save";
          }
          // socketEnvironment;
        Install.WantedBy = ["graphical-session.target"];
      };
    };

    timers.tmux-resurrect-save = {
      Unit.Description = "Periodically save the tmux session state";
      Timer.OnCalendar = "*-*-* *:0/5:00";
      Install.WantedBy = ["timers.target"];
    };
  };
}
