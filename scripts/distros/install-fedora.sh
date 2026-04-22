#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../common.sh
source "$ROOT_DIR/scripts/common.sh"

PKG_FILE="$ROOT_DIR/packages/fedora.txt"

require_os "fedora"
require_file "$PKG_FILE"
load_packages "$PKG_FILE"

dnf copr enable -y jdxcode/mise

# Nushell repo
cat > /etc/yum.repos.d/fury-nushell.repo <<'EOF'
[gemfury-nushell]
name=Gemfury Nushell Repo
baseurl=https://yum.fury.io/nushell/
enabled=1
gpgcheck=0
gpgkey=https://yum.fury.io/nushell/gpg.key
EOF

dnf makecache -y
dnf install -y "${packages[@]}"

log_info "Fedora packages installed."
