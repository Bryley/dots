#!/usr/bin/env bash
set -uo pipefail

# Small, focused smooth scrolling for tmux copy-mode half-page movement.
# Intended for C-u/C-d: snappy animation in a handful of frames rather than
# one slow command per line.
#
# This script is intentionally best-effort and always exits 0. tmux copy-mode
# commands can return non-zero at scroll boundaries or when copy-mode exits;
# surfacing that as a status-bar error is more annoying than useful.

main() {
    local direction="${1:-}"
    local frames="${SMOOTH_SCROLL_FRAMES:-8}"
    local delay="${SMOOTH_SCROLL_DELAY:-0.004}"
    local scroll_command

    case "$direction" in
        up) scroll_command="scroll-up" ;;
        down) scroll_command="scroll-down" ;;
        *) return 0 ;;
    esac

    local target_pane="${TMUX_PANE:-}"
    local target_args=()
    if [ -n "$target_pane" ]; then
        target_args=(-t "$target_pane")
    fi

    local pane_height
    pane_height="$(tmux display-message "${target_args[@]}" -p '#{pane_height}' 2>/dev/null)" || return 0

    local lines=$((pane_height / 2))

    # Keep the animation snappy and avoid division edge cases on tiny panes.
    if [ "$lines" -lt 1 ]; then
        lines=1
    fi
    if [ "$frames" -lt 1 ]; then
        frames=1
    fi
    if [ "$frames" -gt "$lines" ]; then
        frames="$lines"
    fi

    local remaining="$lines"
    local i frames_left chunk

    for ((i = 0; i < frames; i++)); do
        frames_left=$((frames - i))
        chunk=$(((remaining + frames_left - 1) / frames_left))

        tmux send-keys "${target_args[@]}" -X -N "$chunk" "$scroll_command" 2>/dev/null || return 0
        remaining=$((remaining - chunk))

        if [ "$i" -lt $((frames - 1)) ]; then
            sleep "$delay" 2>/dev/null || return 0
        fi
    done
}

main "$@" || true
exit 0
