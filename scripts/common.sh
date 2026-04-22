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

setup_ssh_key_for_target_user() {
    local key_path pub_path
    key_path="/home/$TARGET_USER/.ssh/id_ed25519"
    pub_path="${key_path}.pub"

    sudo -u "$TARGET_USER" bash -lc 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'

    if [[ ! -f "$key_path" ]]; then
        log_info "Generating SSH key for $TARGET_USER"
        sudo -u "$TARGET_USER" ssh-keygen -t ed25519 -a 64 -f "$key_path" -N "" -C "$TARGET_USER@$(hostname)"
    else
        log_info "SSH key already exists for $TARGET_USER."
    fi

    if [[ ! -f "$pub_path" ]]; then
        log_error "Expected SSH public key not found at $pub_path"
        exit 1
    fi

    printf "\n%s\n" "============================================================"
    printf "%s\n" "COPY THIS PUBLIC KEY TO GITHUB (Settings > SSH and GPG keys):"
    printf "%s\n" "$(cat "$pub_path")"
    printf "%s\n\n" "============================================================"
}

ensure_user_in_group() {
    local user="$1"
    local group="$2"

    if getent group "$group" > /dev/null 2>&1; then
        usermod -aG "$group" "$user"
        log_info "Added '$user' to '$group' group."
    else
        log_warn "Group '$group' not found, skipping group setup for '$user'."
    fi
}
