
# TODO NTS: This will not work due to the fact that the tmux server has global
# keybinds for all sessions not just 1. Will have to come up with something
# different or get used to the fact that it will essentially be a tmux window
# inside the window for now.

# source-file ~/.config/tmux/tmux.conf

unbind-key -a

bind-key d detach-client

bind-key h previous-window
bind-key l next-window
bind-key c new-window
bind-key x kill-pane

bind-key w run-shell "pwd"
