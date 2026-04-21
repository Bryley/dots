#!/usr/bin/env bash
set -euo pipefail

# Simple system bootstrap for SSH-friendly CLI usage.
# Mise-managed tools (pi, runtimes, LSP/MCP) live in configs/mise/...

packages=(
    git
    curl
    wget
    tmux
    neovim
    # jq # TODO add apart of mise
    ca-certificates
    gnupg
    libatomic1
    libstdc++6
    sudo
    ffmpeg
    # yt-dlp # TODO add as apart of mise instead
    mise
    nushell
)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

if [[ "$EUID" -ne 0 ]]; then
    log_error "Please run with sudo as the user you want to install under."
    exit 1
fi

if [[ -z "${SUDO_USER:-}" ]]; then
    log_error "SUDO_USER not set. Run with sudo from a non-root user."
    exit 1
fi

TARGET_USER="$SUDO_USER"

if [[ ! -f /etc/os-release ]]; then
    log_error "Cannot detect OS. /etc/os-release not found."
    exit 1
fi

source /etc/os-release

install_ubuntu_debian() {
    apt-get update -y
    apt-get install -y curl gnupg ca-certificates

    # Add mise repo
    if [[ ! -f /etc/apt/sources.list.d/mise.list ]]; then
        install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null
        echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" > /etc/apt/sources.list.d/mise.list
    fi

    # Add nushell
    if [[ ! -f /etc/apt/sources.list.d/fury-nushell.list ]]; then
        install -d -m 0755 /etc/apt/keyrings
        curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
        echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" > /etc/apt/sources.list.d/fury-nushell.list
    fi

    apt-get update -y
    apt-get install -y "${packages[@]}"
}

install_fedora() {
    local packages_fedora=()
    local pkg

    for pkg in "${packages[@]}"; do
        case "$pkg" in
            gnupg)
                packages_fedora+=("gnupg2")
                ;;
            libatomic1)
                packages_fedora+=("libatomic")
                ;;
            libstdc++6)
                packages_fedora+=("libstdc++")
                ;;
            nushell)
                ;;
            *)
                packages_fedora+=("$pkg")
                ;;
        esac
    done

    dnf copr enable -y jdxcode/mise
    dnf install -y "${packages_fedora[@]}"

    if dnf list --available nushell > /dev/null 2>&1; then
        dnf install -y nushell
    else
        log_warn "nushell not found in current Fedora repos, adding fury-nushell repo"
        cat > /etc/yum.repos.d/fury-nushell.repo <<'EOF'
[gemfury-nushell]
name=Gemfury Nushell Repo
baseurl=https://yum.fury.io/nushell/
enabled=1
gpgcheck=0
gpgkey=https://yum.fury.io/nushell/gpg.key
EOF
        dnf makecache -y
        dnf install -y nushell
    fi
}

setup_ssh_key() {
    local key_path pub_path
    key_path="/home/$TARGET_USER/.ssh/id_ed25519"
    pub_path="${key_path}.pub"

    if [[ -f "$key_path" ]]; then
        log_info "SSH key already exists for $TARGET_USER."
    else
        log_info "Generating SSH key for $TARGET_USER"
        sudo -u "$TARGET_USER" bash -lc 'mkdir -p ~/.ssh && chmod 700 ~/.ssh'
        sudo -u "$TARGET_USER" ssh-keygen -t ed25519 -a 64 -f "$key_path" -N "" -C "$TARGET_USER@$(hostname)"
    fi

    if [[ -f "$pub_path" ]]; then
        printf "\n%s\n" "============================================================"
        printf "%s\n" "COPY THIS PUBLIC KEY INTO GITHUB (Settings > SSH keys):"
        printf "%s\n" "$(cat "$pub_path")"
        printf "%s\n\n" "============================================================"
    else
        log_error "Expected SSH public key not found at $pub_path"
        exit 1
    fi
}

case "${ID:-}" in
    ubuntu|debian)
        install_ubuntu_debian
        ;;
    fedora)
        install_fedora
        ;;
    *)
        log_error "Unsupported distro: ${ID:-unknown}."
        exit 1
        ;;
esac

# Setup mise in target user's (and root users) `.bashrc`
sudo -u "$TARGET_USER" bash -lc 'touch ~/.bashrc && grep -Fqx "eval \"\$(mise activate bash)\"" ~/.bashrc || printf "\n# mise\neval \"\$(mise activate bash)\"\n" >> ~/.bashrc'
sudo bash -lc 'touch ~/.bashrc && grep -Fqx "eval \"\$(mise activate bash)\"" ~/.bashrc || printf "\n# mise\neval \"\$(mise activate bash)\"\n" >> ~/.bashrc'

NU_PATH="$(command -v nu || true)"
if [[ -z "$NU_PATH" ]]; then
    log_error "Nushell is not installed or not in PATH."
    exit 1
fi

if ! grep -Fxq "$NU_PATH" /etc/shells; then
    echo "$NU_PATH" >> /etc/shells
fi

chsh -s "$NU_PATH" "$TARGET_USER"

log_info "Default shell set to nushell for $TARGET_USER."

sudo -u "$TARGET_USER" bash "$SCRIPT_DIR/link.sh"

# Install global mise packages from config
sudo -u "$TARGET_USER" mise install

setup_ssh_key

log_info "Done installing, here is a check list of things you might want to do next:"
log_info "  - [ ] Install and setup Cloudflared"
log_info "  - [ ] Install and setup Tailscale"
log_info "  - [ ] Switch dots remote to SSH"
printf "%s\n" "      git -C $SCRIPT_DIR remote set-url origin git@github.com:bryley/dots.git"
log_info "  - [ ] Clone private notes vault"
printf "%s\n" "      git clone git@github.com:bryley/notes.git /home/$TARGET_USER/notes"
