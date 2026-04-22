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
sudo -u "$TARGET_USER" mise install

run_vps=""
if [[ -n "${IS_VPS:-}" ]]; then
    case "${IS_VPS,,}" in
        y|yes|1|true)
            run_vps="yes"
            ;;
        n|no|0|false)
            run_vps="no"
            ;;
        *)
            log_error "Invalid IS_VPS value: $IS_VPS (use yes/no)"
            exit 1
            ;;
    esac
else
    read -r -p "Should this machine run VPS setup? [y/N]: " reply
    case "${reply,,}" in
        y|yes)
            run_vps="yes"
            ;;
        *)
            run_vps="no"
            ;;
    esac
fi

if [[ "$run_vps" == "yes" ]]; then
    log_info "Running VPS setup..."
    bash "$ROOT_DIR/scripts/vps.sh"
fi

log_info "Done, here are the next steps:"
log_info "  - Set $TARGET_USER's passwords if not set using 'passwd $TARGET_USER'"
if [[ "$run_vps" == "yes" ]]; then
    DEPLOY_USER="${DEPLOY_USER:-deployer}"
    log_info "  - Set $DEPLOY_USER's passwords using 'passwd $DEPLOY_USER'"
    log_info "  - From your host, run: scripts/bootstrap-remote-ssh.sh $TARGET_USER@<server-ip-or-hostname>"
fi
log_info "  - Download and install Cloudflared"
log_info "  - Download and install Tailscale"
log_info "  - Switch dots remote to SSH"
printf "%s\n" "      git -C $ROOT_DIR remote set-url origin git@github.com:bryley/dots.git"

