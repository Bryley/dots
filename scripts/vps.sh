#!/usr/bin/env bash
set -euo pipefail

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

sync_authorized_keys_to_deployer() {
    local target_auth deploy_auth
    target_auth="/home/$TARGET_USER/.ssh/authorized_keys"
    deploy_auth="/home/$DEPLOY_USER/.ssh/authorized_keys"

    install -d -m 700 -o "$TARGET_USER" -g "$TARGET_USER" "/home/$TARGET_USER/.ssh"
    install -d -m 700 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"

    touch "$target_auth" "$deploy_auth"
    chown "$TARGET_USER:$TARGET_USER" "$target_auth"
    chown "$DEPLOY_USER:$DEPLOY_USER" "$deploy_auth"
    chmod 600 "$target_auth" "$deploy_auth"

    # Ensure target user's own public key exists in its authorized_keys.
    if ! grep -Fxq "$(cat /home/$TARGET_USER/.ssh/id_ed25519.pub)" "$target_auth"; then
        cat "/home/$TARGET_USER/.ssh/id_ed25519.pub" >> "$target_auth"
    fi

    # Copy every key from target user to deployer so both users can be used to log in.
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if ! grep -Fxq "$line" "$deploy_auth"; then
            echo "$line" >> "$deploy_auth"
        fi
    done < "$target_auth"

    log_info "Synced authorized_keys from '$TARGET_USER' to '$DEPLOY_USER'."
}

is_laptop_machine() {
    if compgen -G "/sys/class/power_supply/BAT*" > /dev/null; then
        return 0
    fi

    if command -v hostnamectl > /dev/null 2>&1; then
        case "$(hostnamectl chassis 2>/dev/null || true)" in
            laptop|notebook|portable|tablet)
                return 0
                ;;
        esac
    fi

    return 1
}

configure_laptop_server_power_mode() {
    log_info "Laptop detected. Configuring lid/sleep behavior for server usage..."

    install -d -m 755 /etc/systemd/logind.conf.d
    cat > /etc/systemd/logind.conf.d/99-dots-server.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF

    if command -v systemctl > /dev/null 2>&1; then
        systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target > /dev/null 2>&1 || true
        systemctl restart systemd-logind > /dev/null 2>&1 || log_warn "Could not restart systemd-logind automatically."
    else
        log_warn "systemctl not found. Please restart systemd-logind manually."
    fi

    log_info "Laptop power settings updated for always-on server mode."
}

setup_copyparty_shared_dirs() {
    local base="/srv/copyparty"

    install -d -m 2775 -o "$DEPLOY_USER" -g "$DEPLOY_USER" "$base" "$base/notes" "$base/sessions"

    # keep group-write on new files/dirs so TARGET_USER and DEPLOY_USER can both edit
    if command -v setfacl > /dev/null 2>&1; then
        setfacl -m g::rwx "$base" "$base/notes" "$base/sessions"
        setfacl -d -m g::rwx "$base" "$base/notes" "$base/sessions"
    fi

    log_info "Prepared shared dirs: $base/{notes,sessions}"
}

if [[ ! -f "/home/$TARGET_USER/.ssh/id_ed25519" ]]; then
    setup_ssh_key_for_target_user
fi

ensure_deploy_user
copy_target_key_to_deploy_user
sync_authorized_keys_to_deployer
ensure_user_sudo_access "$TARGET_USER"
ensure_user_sudo_access "$DEPLOY_USER"
ensure_user_in_group "$TARGET_USER" docker
ensure_user_in_group "$DEPLOY_USER" docker
ensure_user_in_group "$TARGET_USER" "$DEPLOY_USER"

setup_copyparty_shared_dirs

if is_laptop_machine; then
    configure_laptop_server_power_mode
fi

log_info "Done VPS setup."
