#!/usr/bin/env bash
set -euo pipefail

# Will usally be `~/dots` expanded for the current user
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=./scripts/common.sh
source "$ROOT_DIR/scripts/common.sh"

require_sudo_user

# Export so child scripts run with `bash ...` can reuse them.
export ROOT_DIR
export TARGET_USER

if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

source /etc/os-release

DISTRO_SCRIPT=""
case "${ID:-}" in
    ubuntu)
        DISTRO_SCRIPT="$ROOT_DIR/scripts/distros/install-ubuntu.sh"
        ;;
    fedora)
        DISTRO_SCRIPT="$ROOT_DIR/scripts/distros/install-fedora.sh"
        ;;
    *)
        log_error "Unsupported distro: ${ID:-unknown}."
        exit 1
        ;;
esac

require_file "$DISTRO_SCRIPT"

log_info "Installing distro packages (${ID})..."
bash "$DISTRO_SCRIPT"

log_info "Running shared setup..."
setup_mise_bashrc
set_nushell_default false
sudo -u "$TARGET_USER" bash "$ROOT_DIR/link.sh"

# Install tmux custom terminfo system-wide so non-user contexts can resolve TERM=tmux-256color-uc.
if command -v tic >/dev/null 2>&1; then
    tic -x -o /usr/local/share/terminfo "$ROOT_DIR/configs/tmux/tmux-256color-uc.terminfo" || log_warn "Failed to install system-wide tmux terminfo entry"
fi

if [[ -f "$ROOT_DIR/mise.toml" ]]; then
    sudo -u "$TARGET_USER" mise trust "$ROOT_DIR/mise.toml"
fi
sudo -u "$TARGET_USER" mise install

setup_ssh_key_for_target_user
ensure_user_in_group "$TARGET_USER" docker

resolve_install_type() {
    local value="${INSTALL_TYPE:-}"

    if [[ -z "$value" ]]; then
        if [[ -t 0 ]]; then
            read -r -p "Install type? [v]ps / [d]esktop (Enter to skip): " value
        else
            echo "none"
            return 0
        fi
    fi

    case "${value,,}" in
        v|vps)
            echo "vps"
            ;;
        d|desktop)
            echo "desktop"
            ;;
        "")
            echo "none"
            ;;
        *)
            log_error "Invalid INSTALL_TYPE: $value (use vps|v or desktop|d)"
            exit 1
            ;;
    esac
}

install_type="$(resolve_install_type)"

case "$install_type" in
    vps)
        log_info "Running VPS setup..."
        bash "$ROOT_DIR/scripts/vps.sh"
        ;;
    desktop)
        log_info "Running desktop setup..."
        bash "$ROOT_DIR/scripts/desktop.sh"
        ;;
    none)
        log_warn "Skipping VPS/Desktop setup."
        ;;
esac

log_info "Done, here are the next steps:"
log_info "  - Switch dots remote to SSH"
printf "%s\n" "      git -C $ROOT_DIR remote set-url origin git@github.com:bryley/dots.git"
log_info "  - Set $TARGET_USER's passwords if not already set using 'sudo passwd $TARGET_USER'"
if [[ "$install_type" == "vps" ]]; then
    DEPLOY_USER="${DEPLOY_USER:-deployer}"
    log_info "  - Set $DEPLOY_USER's passwords using 'sudo passwd $DEPLOY_USER'"
    log_info "  - From your host, run: scripts/bootstrap-remote-ssh.sh $TARGET_USER@<server-ip-or-hostname>"
fi
log_info "  - Download and install Tailscale"
log_info "  - Download and install Cloudflared"

