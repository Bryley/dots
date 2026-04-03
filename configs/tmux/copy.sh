#!/usr/bin/env bash

# Read stdin into clipboard using whatever is available.
if command -v pbcopy >/dev/null 2>&1; then
  exec pbcopy
elif command -v wl-copy >/dev/null 2>&1; then
  exec wl-copy
elif command -v xclip >/dev/null 2>&1; then
  exec xclip -i -selection clipboard
elif command -v xsel >/dev/null 2>&1; then
  exec xsel --input --clipboard
else
  # Fallback: OSC52 directly to the real TTY (still works outside popups)
  text=$(cat)
  encoded=$(printf '%s' "$text" | base64 | tr -d '\n')
  printf '\033]52;c;%s\a' "$encoded" > "$(tmux display-message -p '#{client_tty}')"
fi
