#!/usr/bin/env bash

# SESSION="_popup"   # background session name
POPUP_SESSION="_popup_$(tmux display -p '#{window_id}')"
CURRENT_SESSION="$(tmux display-message -p '#S')"
WIDTH="50%"
HEIGHT="50%"

# Get current pane's directory to start popup in something sensible
CUR_DIR="$(tmux display -p -F "#{pane_current_path}")"

if [[ $CURRENT_SESSION == _popup* ]]; then
    tmux detach-client
    exit 0
fi

# If the session doesn't exist, create it (detached)
if ! tmux has-session -t "$POPUP_SESSION" 2>/dev/null; then
    tmux -f "$HOME/.config/tmux/tmux-pop/config.tmux" new-session -d -s "$POPUP_SESSION" -n main -c "$CUR_DIR"
fi

# Show the session inside a popup
tmux display-popup -w "$WIDTH" -h "$HEIGHT" -E "tmux attach -t $POPUP_SESSION"
