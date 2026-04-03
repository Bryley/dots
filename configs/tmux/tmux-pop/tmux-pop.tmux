# Where the plugin lives
set-environment -g @popup_plugin_dir "~/.config/tmux/tmux-pop"

# Keybinding: open the popup scratch session
bind-key f run-shell "sh \"#{@popup_plugin_dir}/scripts/toggle.sh\""
