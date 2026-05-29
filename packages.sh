#!/usr/bin/env bash
set -euo pipefail

packages=(
    git
    curl
    neovim
    nushell
    ripgrep
    fd
    tmux
    ncurses
    mise
    pciutils # For lspci
    wofi

    mangowc
    elogind # Seat service and connector to display server for wayland compositor
    mesa-dri # Drivers for graphics
    swww # Wallpaper
    quickshell
    noto-fonts-ttf
    noto-fonts-emoji
    net-tools

    polkit # Auth
    tlp # For laptop power management
    lxqt-policykit

    pipewire
    alsa-pipewire
    pulseaudio-utils
    pavucontrol

    ghostty
)

# TODO:
# - [ ] Video Accelleration (may need different paths based on graphics card)
# - [ ] ifconfig command whatever that is?
# - [ ] Nvidia potentially?
# - [ ] Check wifi fix for this computer

xbps-install -Sy void-repo-nonfree
xbps-install -y "${packages[@]}"

# Install helium custom browser
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
"$script_dir/install-helium-xbps.sh"

# Enable services
ln -sf /etc/sv/elogind /var/service/
ln -sf /etc/sv/tlp /var/service/

# Laptop stuff
if [ -d /sys/class/power_supply/BAT0 ] || ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
   xbps-install -S tlp
   ln -sf /etc/sv/tlp /var/service/
fi

