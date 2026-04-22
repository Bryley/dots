#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${ROOT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=./common.sh
source "$ROOT_DIR/scripts/common.sh"

require_sudo_user

MOUNT_BASE="${MOUNT_BASE:-/home/$TARGET_USER}"
WEBDAV_BASE_URL="${WEBDAV_BASE_URL:-https://copyparty.bryleybytes.com}"
WEBDAV_VENDOR="${WEBDAV_VENDOR:-owncloud}"

require_tools() {
    if ! command -v rclone > /dev/null 2>&1; then
        log_error "rclone is not installed. Install it first and rerun this script."
        exit 1
    fi

    if ! command -v systemctl > /dev/null 2>&1; then
        log_error "systemctl is required for desktop mount services."
        exit 1
    fi
}

setup_mount_dirs() {
    for name in notes sessions; do
        local path="$MOUNT_BASE/$name"

        if [[ -L "$path" ]]; then
            rm -f "$path"
        elif [[ -e "$path" && ! -d "$path" ]]; then
            log_error "$path exists and is not a directory. Move it and rerun."
            exit 1
        fi

        install -d -m 755 "$path"
        chown "$TARGET_USER:$TARGET_USER" "$path"
    done

    log_info "Prepared mount directories: $MOUNT_BASE/{notes,sessions}"
}

write_mount_service() {
    local name="$1"
    local uid gid unit_name local_path remote_url base_url

    uid="$(id -u "$TARGET_USER")"
    gid="$(id -g "$TARGET_USER")"
    unit_name="rclone-copyparty-${name}.service"
    local_path="$MOUNT_BASE/$name"
    base_url="${WEBDAV_BASE_URL%/}"
    remote_url="$base_url/$name"

    cat > "/etc/systemd/system/$unit_name" <<EOF
[Unit]
Description=Rclone WebDAV mount for copyparty $name
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$TARGET_USER
Group=$TARGET_USER
ExecStart=/usr/bin/rclone mount :webdav: $local_path --config /dev/null --webdav-url $remote_url --webdav-vendor $WEBDAV_VENDOR --vfs-cache-mode writes --dir-cache-time 5s --poll-interval 10s --uid $uid --gid $gid --umask 002
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    log_info "Wrote systemd service: $unit_name"
}

enable_services() {
    systemctl daemon-reload

    for name in notes sessions; do
        local unit_name="rclone-copyparty-${name}.service"
        systemctl enable --now "$unit_name"
        log_info "Enabled $unit_name"
    done
}

require_tools
setup_mount_dirs
write_mount_service notes
write_mount_service sessions
enable_services

log_info "Done desktop setup."
log_info "WebDAV base URL: ${WEBDAV_BASE_URL%/}"
