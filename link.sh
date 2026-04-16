#!/usr/bin/env bash
set -euo pipefail

CONFIGS_DIR="$(realpath "$(dirname "${BASH_SOURCE[0]}")")/configs"

color_green="\033[0;32m"
color_yellow="\033[0;33m"
color_red="\033[0;31m"
color_reset="\033[0m"

log_info() {
    printf "%b%s%b\n" "$color_green" "$1" "$color_reset"
}

log_warn() {
    printf "%b%s%b\n" "$color_yellow" "$1" "$color_reset"
}

log_error() {
    printf "%b%s%b\n" "$color_red" "$1" "$color_reset"
}

mkdir -p "$HOME/.config"

link() {
    local source="$CONFIGS_DIR/$1"
    local target="$2"

    mkdir -p "$(dirname "$target")"

    if [[ -L "$target" ]]; then
        log_warn "Link '$target' already exists, replacing it..."
        rm "$target"
    elif [[ -e "$target" ]]; then
        log_error "'$target' already exists, move it somewhere else and run the './link.sh' command again"
        return
    fi

    ln -s "$source" "$target"
    log_info "Setup link '$source' -> '$target'"
}

link "carapace" "$HOME/.config/carapace"
link "hypr" "$HOME/.config/hypr"
link "kitty" "$HOME/.config/kitty"
link "mise" "$HOME/.config/mise"
link "niri" "$HOME/.config/niri"
link "nushell" "$HOME/.config/nushell"
link "opencode" "$HOME/.config/opencode"
link "presenterm" "$HOME/.config/presenterm"
link "quickshell" "$HOME/.config/quickshell"
link "television" "$HOME/.config/television"
link "tmux" "$HOME/.config/tmux"
link "wofi" "$HOME/.config/wofi"
link "ghostty" "$HOME/.config/ghostty"

link "git/.gitconfig" "$HOME/.gitconfig"
link "pi" "$HOME/.pi"
link "wallpaper.png" "$HOME/wallpaper"
