#!/usr/bin/env bash

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TARGET_USER="${SUDO_USER:-}"

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

require_sudo_user() {
    if [[ "$EUID" -ne 0 ]]; then
        log_error "Please run with sudo as the user you want to install under."
        exit 1
    fi

    if [[ -z "$TARGET_USER" ]]; then
        log_error "SUDO_USER not set. Run with sudo from a non-root user."
        exit 1
    fi
}

require_os() {
    local expected_id="$1"

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS. /etc/os-release not found."
        exit 1
    fi

    source /etc/os-release
    if [[ "${ID:-}" != "$expected_id" ]]; then
        log_error "This script is for $expected_id only. Detected: ${ID:-unknown}."
        exit 1
    fi
}

require_file() {
    local path="$1"
    if [[ ! -f "$path" ]]; then
        log_error "Missing file: $path"
        exit 1
    fi
}

load_packages() {
    local pkg_file="$1"
    mapfile -t packages < <(grep -Ev '^\s*#|^\s*$' "$pkg_file")
}

setup_mise_bashrc() {
    sudo -u "$TARGET_USER" bash -lc 'touch ~/.bashrc && grep -Fqx "eval \"\$(mise activate bash)\"" ~/.bashrc || printf "\n# mise\neval \"\$(mise activate bash)\"\n" >> ~/.bashrc'
    sudo bash -lc 'touch ~/.bashrc && grep -Fqx "eval \"\$(mise activate bash)\"" ~/.bashrc || printf "\n# mise\neval \"\$(mise activate bash)\"\n" >> ~/.bashrc'
}

set_nushell_default() {
    local required="${1:-false}"
    local nu_path

    nu_path="$(command -v nu || true)"
    if [[ -z "$nu_path" ]]; then
        if [[ "$required" == "true" ]]; then
            log_error "Nushell is not installed or not in PATH."
            exit 1
        fi
        log_warn "Nushell not found in PATH, skipping chsh."
        return 0
    fi

    if ! grep -Fxq "$nu_path" /etc/shells; then
        echo "$nu_path" >> /etc/shells
    fi

    chsh -s "$nu_path" "$TARGET_USER"
    log_info "Default shell set to nushell for $TARGET_USER."
}
