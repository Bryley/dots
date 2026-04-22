#!/usr/bin/env bash
set -euo pipefail

# This file uses docker to test that the scripts work on fresh ubuntu and
# fedora machines

if ! command -v docker &> /dev/null; then
    echo "docker is required to run this test."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install.sh"
TESTS_DIR="$SCRIPT_DIR/tests"
# shellcheck source=./scripts/common.sh
source "$SCRIPT_DIR/scripts/common.sh"

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

if [[ "$DISTRO" == "ubuntu" ]]; then
    docker exec -u tester "$NAME" sudo IS_VPS=yes /workspace/install.sh
else
    docker exec -u tester "$NAME" sudo IS_VPS=no /workspace/install.sh
fi

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
check "ffmpeg installed" "command -v ffmpeg"
check "docker installed" "command -v docker"
check "tester default shell is nushell" "test \"\$(getent passwd tester | cut -d: -f7)\" = \"\$(command -v nu)\""

check "mise link" "test -L /home/tester/.config/mise"
check "nushell link" "test -L /home/tester/.config/nushell"
check "tmux link" "test -L /home/tester/.config/tmux"
check "gitconfig link" "test -L /home/tester/.gitconfig"
check "copyparty link" "test -L /home/tester/copyparty"
check "no root mise link" "test ! -e /root/.config/mise"
check "tester ssh public key exists" "test -f /home/tester/.ssh/id_ed25519.pub"

if [[ "$DISTRO" == "ubuntu" ]]; then
    sleep 2
    check "mise apt dots" "test -f /etc/apt/sources.list.d/mise.list"
    check "nushell apt dots" "test -f /etc/apt/sources.list.d/fury-nushell.list"

    check "vps: deploy user exists" "id deployer"
    check "vps: deploy ssh public key exists" "test -f /home/deployer/.ssh/id_ed25519.pub"
    check "vps: deploy has same public key as tester" "cmp -s /home/tester/.ssh/id_ed25519.pub /home/deployer/.ssh/id_ed25519.pub"
    check "vps: tester is in docker group" "id tester | grep -q '(docker)'"
    check "vps: deployer is in docker group" "id deployer | grep -q '(docker)'"
    check "vps: tester is in copyparty group" "id tester | grep -q '(copyparty)'"
    check "vps: deployer is in copyparty group" "id deployer | grep -q '(copyparty)'"
    check "vps: tester sudo access" "sudo -u tester sudo -n true"
    check "vps: deployer sudo access" "sudo -u deployer sudo -n true"

    check "vps: copyparty shared dir exists" "test -d /srv/copyparty"
    check "vps: copyparty shared dir owner/group" "test \"$(stat -c '%U:%G' /srv/copyparty)\" = 'deployer:copyparty'"
    check "vps: copyparty shared dir mode" "test \"$(stat -c '%a' /srv/copyparty)\" = '2775'"
    check "vps: tester can create folder+file in /srv/copyparty" "sudo -u tester bash -lc 'mkdir -p /srv/copyparty/tester-dir && echo ok > /srv/copyparty/tester-dir/.perm-test && test -f /srv/copyparty/tester-dir/.perm-test'"
    check "vps: deployer can modify tester-created file" "sudo -u deployer bash -lc 'echo ok2 >> /srv/copyparty/tester-dir/.perm-test && grep -q ok2 /srv/copyparty/tester-dir/.perm-test'"
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
