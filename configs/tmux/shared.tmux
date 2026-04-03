
# Rebind prefix to Ctrl-A instead of Ctrl-B
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Setup best color support
set-option -gs default-terminal "tmux-256color"
set -as terminal-features ",xterm-256color:RGB,xterm-kitty:RGB"

# Quicker Esc time (handy for neovim)
set -sg escape-time 10

# Decreases repeat time for speed
set -g repeat-time 150

# Enable mouse scrolling and stuff
setw -g mouse on

# Let terminal emulator protocols work (example display images in terminal)
set -g allow-passthrough on

# Enable clipboard
set -g set-clipboard external
set -s copy-command '$HOME/.config/tmux/copy.sh'

# Bind keyboard yanks in copy-mode-vi to use copy-command
bind -T copy-mode-vi y     send -X copy-pipe-and-cancel
bind -T copy-mode-vi Enter send -X copy-pipe-and-cancel

bind -T copy-mode-vi MouseDragEnd1Pane send -X copy-pipe-and-cancel

# Set longer history
set -g history-limit 100000


# Set VI keybindings
setw -g mode-keys vi
set  -g status-keys vi

# Better support for applications like Nvim
set -g focus-events on

# Set default shell to nu
set -g default-command "nu -l"


# Some handy rebinds
bind | split-window -h -c "#{pane_current_path}"
bind _ split-window -v -c "#{pane_current_path}"

# Keep zoom when moving between panes (prefix + hjkl)
bind h if-shell -F "#{window_zoomed_flag}" "select-pane -L \; resize-pane -Z" "select-pane -L"
bind j if-shell -F "#{window_zoomed_flag}" "select-pane -D \; resize-pane -Z" "select-pane -D"
bind k if-shell -F "#{window_zoomed_flag}" "select-pane -U \; resize-pane -Z" "select-pane -U"
bind l if-shell -F "#{window_zoomed_flag}" "select-pane -R \; resize-pane -Z" "select-pane -R"

bind r source-file ~/.config/tmux/tmux.conf

# Auto-detect macOS theme once per server
if-shell '[ "$(uname -s)" = "Darwin" ]' 'run-shell "if [ -z \"$(tmux show -gv @theme_autodetected)\" ]; then tmux set -g @theme_autodetected 1; if osascript -e \"tell application \\\"System Events\\\" to get dark mode\" | grep -q true; then tmux source-file \"$HOME/.config/tmux/tmux.conf\"; else tmux source-file \"$HOME/.config/tmux/tmux-light.conf\"; fi; fi"'
