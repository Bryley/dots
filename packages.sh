#!/usr/bin/env bash
set -euo pipefail

packages=(
    git
    curl
    neovim
    nushell
    ripgrep
    fd
    tmux
    ncurses
    mise
)

sudo xbps-install -Sy "${packages[@]}"
