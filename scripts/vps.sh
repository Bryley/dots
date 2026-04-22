#!/usr/bin/env bash
set -euo pipefail

# TODO:
# - [ ] Disable SSH password auth

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=./common.sh
source "$ROOT_DIR/scripts/common.sh"

require_sudo_user

DEPLOY_USER="${DEPLOY_USER:-deployer}"

ensure_user_sudo_access() {
    local user="$1"

    if getent group sudo > /dev/null 2>&1; then
        usermod -aG sudo "$user"
    elif getent group wheel > /dev/null 2>&1; then
        usermod -aG wheel "$user"
    fi

    printf "%s\n" "$user ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-dots-${user}"
    chmod 440 "/etc/sudoers.d/90-dots-${user}"
}

ensure_target_ssh_key() {
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

ensure_deploy_user() {
    if id "$DEPLOY_USER" > /dev/null 2>&1; then
        log_info "Deploy user '$DEPLOY_USER' already exists."
    else
        log_info "Creating deploy user '$DEPLOY_USER'"
        adduser --disabled-password --gecos "" "$DEPLOY_USER"
        usermod -L "$DEPLOY_USER"
    fi
}

copy_target_key_to_deploy_user() {
    local src_key src_pub dst_ssh
    src_key="/home/$TARGET_USER/.ssh/id_ed25519"
    src_pub="${src_key}.pub"
    dst_ssh="/home/$DEPLOY_USER/.ssh"

    install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$dst_ssh"

    cp "$src_key" "$dst_ssh/id_ed25519"
    cp "$src_pub" "$dst_ssh/id_ed25519.pub"

    chown "$DEPLOY_USER:$DEPLOY_USER" "$dst_ssh/id_ed25519" "$dst_ssh/id_ed25519.pub"
    chmod 600 "$dst_ssh/id_ed25519"
    chmod 644 "$dst_ssh/id_ed25519.pub"

    log_info "Copied SSH keypair from '$TARGET_USER' to '$DEPLOY_USER'."
}

ensure_target_ssh_key
ensure_deploy_user
copy_target_key_to_deploy_user
ensure_user_sudo_access "$TARGET_USER"
ensure_user_sudo_access "$DEPLOY_USER"

log_info "Done VPS setup."
