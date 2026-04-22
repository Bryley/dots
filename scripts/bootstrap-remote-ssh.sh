#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "$SCRIPT_DIR/common.sh"

usage() {
    cat <<'EOF'
Usage:
  scripts/bootstrap-remote-ssh.sh user@host [--key /path/to/key.pub] [--port 22] [--no-harden]

Examples:
  scripts/bootstrap-remote-ssh.sh bryley@203.0.113.10
  scripts/bootstrap-remote-ssh.sh root@my-vps --key ~/.ssh/id_ed25519.pub --port 2222

What it does:
  1) Adds the provided public key to the remote user's ~/.ssh/authorized_keys
  2) Optionally hardens OpenSSH (enabled by default):
     - PasswordAuthentication no
     - KbdInteractiveAuthentication no
     - ChallengeResponseAuthentication no
     - PermitRootLogin no
     - PubkeyAuthentication yes
  3) Validates sshd config and reloads ssh service
EOF
}

if ! command -v ssh > /dev/null 2>&1; then
    log_error "ssh is required on the host machine."
    exit 1
fi

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    usage
    exit 1
fi
shift || true

KEY_PATH="${HOME}/.ssh/id_ed25519.pub"
SSH_PORT="22"
HARDEN="yes"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --key)
            KEY_PATH="${2:-}"
            shift 2
            ;;
        --port)
            SSH_PORT="${2:-}"
            shift 2
            ;;
        --no-harden)
            HARDEN="no"
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown argument: $1"
            usage
            exit 1
            ;;
    esac
done

if [[ ! -f "$KEY_PATH" ]]; then
    log_error "Public key not found: $KEY_PATH"
    exit 1
fi

PUBLIC_KEY="$(<"$KEY_PATH")"
if [[ "$PUBLIC_KEY" != ssh-* ]]; then
    log_error "File does not look like an SSH public key: $KEY_PATH"
    exit 1
fi

KEY_B64="$(printf '%s' "$PUBLIC_KEY" | base64 | tr -d '\n')"

log_info "Connecting to $TARGET ..."
ssh -p "$SSH_PORT" "$TARGET" "KEY_B64='$KEY_B64' HARDEN='$HARDEN' bash -s" <<'REMOTE'
set -euo pipefail

if ! command -v sudo > /dev/null 2>&1; then
  echo "sudo is required on remote host" >&2
  exit 1
fi

PUBLIC_KEY="$(printf '%s' "$KEY_B64" | base64 -d)"
REMOTE_USER="$(id -un)"
HOME_DIR="$(getent passwd "$REMOTE_USER" | cut -d: -f6)"
AUTH_DIR="$HOME_DIR/.ssh"
AUTH_KEYS="$AUTH_DIR/authorized_keys"

sudo install -d -m 700 -o "$REMOTE_USER" -g "$REMOTE_USER" "$AUTH_DIR"
sudo touch "$AUTH_KEYS"
sudo chown "$REMOTE_USER:$REMOTE_USER" "$AUTH_KEYS"
sudo chmod 600 "$AUTH_KEYS"

if sudo grep -Fxq "$PUBLIC_KEY" "$AUTH_KEYS"; then
  echo "SSH key already present for $REMOTE_USER"
else
  printf '%s\n' "$PUBLIC_KEY" | sudo tee -a "$AUTH_KEYS" > /dev/null
  echo "Added SSH key for $REMOTE_USER"
fi

if [[ "$HARDEN" == "yes" ]]; then
  HARDEN_FILE="/etc/ssh/sshd_config.d/99-dots-hardening.conf"
  TMP_FILE="$(mktemp)"

  cat > "$TMP_FILE" <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
ChallengeResponseAuthentication no
PermitRootLogin no
PubkeyAuthentication yes
EOF

  if sudo test -f "$HARDEN_FILE" && sudo cmp -s "$TMP_FILE" "$HARDEN_FILE"; then
    echo "SSH hardening already configured"
    rm -f "$TMP_FILE"
  else
    sudo install -d -m 755 /etc/ssh/sshd_config.d
    sudo cp "$TMP_FILE" "$HARDEN_FILE"
    sudo chmod 644 "$HARDEN_FILE"
    rm -f "$TMP_FILE"
    echo "Wrote SSH hardening config: $HARDEN_FILE"
  fi

  sudo sshd -t

  if sudo systemctl list-unit-files ssh.service > /dev/null 2>&1; then
    sudo systemctl reload ssh
  else
    sudo systemctl reload sshd
  fi

  echo "OpenSSH reloaded"
else
  echo "Skipping SSH hardening (--no-harden)"
fi
REMOTE

log_info "Done."
log_warn "Keep your current SSH session open while verifying a new login works."
