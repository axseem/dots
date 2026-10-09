if status is-interactive; and not set -q TMUX; and not set -q TMUX_AUTOSTART_DISABLED; and command -q tmux
    # tmux-session gives every terminal its own grouped session over one
    # shared window pool. Fall back to the plain attach if the launcher fails,
    # so a broken launcher cannot lock the desktop out of terminals.
    if command -q tmux-session
        tmux-session
        and exit
    end
    exec tmux new-session -A -s main
end
