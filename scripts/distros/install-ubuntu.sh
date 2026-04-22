#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../common.sh
source "$ROOT_DIR/scripts/common.sh"

PKG_FILE="$ROOT_DIR/packages/ubuntu.txt"

require_os "ubuntu"
require_file "$PKG_FILE"
load_packages "$PKG_FILE"

apt-get update -y
apt-get install -y curl gnupg ca-certificates

# Mise repo
if [[ ! -f /etc/apt/sources.list.d/mise.list ]]; then
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://mise.jdx.dev/gpg-key.pub | tee /etc/apt/keyrings/mise-archive-keyring.asc > /dev/null
    echo "deb [signed-by=/etc/apt/keyrings/mise-archive-keyring.asc] https://mise.jdx.dev/deb stable main" > /etc/apt/sources.list.d/mise.list
fi

# Nushell repo
if [[ ! -f /etc/apt/sources.list.d/fury-nushell.list ]]; then
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL https://apt.fury.io/nushell/gpg.key | gpg --dearmor -o /etc/apt/keyrings/fury-nushell.gpg
    echo "deb [signed-by=/etc/apt/keyrings/fury-nushell.gpg] https://apt.fury.io/nushell/ /" > /etc/apt/sources.list.d/fury-nushell.list
fi

apt-get update -y
apt-get install -y "${packages[@]}"

log_info "Ubuntu packages installed."
