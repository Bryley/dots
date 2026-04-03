#!/usr/bin/env bash
set -euo pipefail

# This file uses docker to test that the scripts work on fresh ubuntu and
# fedora machines

if ! command -v docker &> /dev/null; then
    echo "docker is required to run this test."
    exit 1
fi

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
TESTS_DIR="$SCRIPT_DIR/tests"

if [[ ! -f "$INSTALL_SCRIPT" ]]; then
    log_error "install.sh not found at $INSTALL_SCRIPT"
    exit 1
fi

read -r -p "Test which distro? (ubuntu/fedora) [ubuntu]: " DISTRO
DISTRO="${DISTRO:-ubuntu}"

case "$DISTRO" in
    ubuntu)
        TEST_IMAGE="dots-test-ubuntu:latest"
        DOCKERFILE="$TESTS_DIR/Dockerfile.ubuntu"
        ;;
    fedora)
        TEST_IMAGE="dots-test-fedora:latest"
        DOCKERFILE="$TESTS_DIR/Dockerfile.fedora"
        ;;
    *)
        log_error "Unknown distro: $DISTRO"
        exit 1
        ;;
esac

NAME="dots-install-test-${DISTRO}"

docker rm -f "$NAME" > /dev/null 2>&1 || true

if [[ ! -f "$DOCKERFILE" ]]; then
    log_error "Dockerfile not found at $DOCKERFILE"
    exit 1
fi

log_info "Building test image: $TEST_IMAGE"
docker build -t "$TEST_IMAGE" -f "$DOCKERFILE" "$SCRIPT_DIR"

docker run -d --rm --name "$NAME" --privileged --cgroupns=host -v /sys/fs/cgroup:/sys/fs/cgroup:rw "$TEST_IMAGE" > /dev/null
sleep 3

log_info "Copying repo into container"
docker cp "$SCRIPT_DIR/." "$NAME:/workspace"
docker exec "$NAME" bash -lc "chown -R tester:tester /workspace"

docker exec -u tester "$NAME" sudo /workspace/install.sh

fail=0

check() {
    local label="$1"
    local cmd="$2"

    if docker exec "$NAME" bash -lc "$cmd" > /dev/null 2>&1; then
        log_info "PASS: $label"
    else
        log_error "FAIL: $label"
        fail=1
    fi
}

check "nu installed" "command -v nu"
check "mise installed" "command -v mise"
check "git installed" "command -v git"
check "curl installed" "command -v curl"
check "tmux installed" "command -v tmux"
check "nvim installed" "command -v nvim"
check "jq installed" "command -v jq"
check "opencode installed" "sudo -u tester test -x /home/tester/.local/share/mise/shims/opencode"
check "opencode on tester path" "sudo -u tester bash -ic 'command -v opencode >/dev/null'"
check "tester default shell is nushell" "test \"\$(getent passwd tester | cut -d: -f7)\" = \"\$(command -v nu)\""

check "mise link" "test -L /home/tester/.config/mise"
check "nushell link" "test -L /home/tester/.config/nushell"
check "tmux link" "test -L /home/tester/.config/tmux"
check "gitconfig link" "test -L /home/tester/.gitconfig"
check "no root mise link" "test ! -e /root/.config/mise"
check "ssh public key exists" "test -f /home/tester/.ssh/id_ed25519.pub"

if [[ "$DISTRO" == "ubuntu" ]]; then
    sleep 2
    check "mise apt dots" "test -f /etc/apt/sources.list.d/mise.list"
    check "nushell apt dots" "test -f /etc/apt/sources.list.d/fury-nushell.list"
    check "opencode service link" "test -L /home/tester/.config/systemd/user/opencode.service"
    check "opencode service command" "grep -q 'ExecStart=.*opencode serve --hostname 0.0.0.0 --port 4444' /home/tester/.config/systemd/user/opencode.service"
    check "opencode process on 4444" "pgrep -u tester -f 'opencode serve --hostname 0.0.0.0 --port 4444' > /dev/null"
    check "port 4444 is reachable" "timeout 2 bash -lc '</dev/tcp/127.0.0.1/4444'"
else
    check "mise copr enabled" "dnf copr list | grep -q jdxcode/mise"
fi

read -r -p "Keep container running? (y/N): " KEEP
KEEP="${KEEP:-N}"

if [[ "$KEEP" != "y" && "$KEEP" != "Y" ]]; then
    docker rm -f "$NAME" > /dev/null
    log_info "Container removed."
else
    log_warn "Container still running: $NAME"
    log_info "Open a shell: docker exec -it $NAME bash"
    log_info "Open as tester: docker exec -it -u tester $NAME bash"
fi

if [[ "$fail" -ne 0 ]]; then
    exit 1
fi
