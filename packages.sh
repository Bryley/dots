#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mapfile -t packages < <(
   sed 's/#.*//' "$script_dir/packages.txt" | awk 'NF { print $1 }'
)
mapfile -t services < <(
   sed 's/#.*//' "$script_dir/services.txt" | awk 'NF { print $1 }'
)

xbps-install -Sy void-repo-nonfree
xbps-install -Sy "${packages[@]}"

# Install helium custom browser
"$script_dir/install-helium-xbps.sh"

enable_service() {
    local service="$1"
    local service_dir="/etc/runit/runsvdir/default"
    local service_source="/etc/sv/$service"
    local red="\033[0;31m"
    local reset="\033[0m"

    if [ ! -d "$service_source" ]; then
        printf "%bError: service does not exist, skipping: %s%b\n" "$red" "$service_source" "$reset" >&2
        return 0
    fi

    if [ ! -d "$service_dir" ] && [ -d /var/service ]; then
        service_dir="/var/service"
    fi

    mkdir -p "$service_dir"
    ln -sfn "$service_source" "$service_dir/$service"
}

for service in "${services[@]}"; do
    enable_service "$service"
done

# PipeWire audio setup
mkdir -p /etc/pipewire/pipewire.conf.d
ln -sfn /usr/share/examples/wireplumber/10-wireplumber.conf \
    /etc/pipewire/pipewire.conf.d/10-wireplumber.conf
ln -sfn /usr/share/examples/pipewire/20-pipewire-pulse.conf \
    /etc/pipewire/pipewire.conf.d/20-pipewire-pulse.conf

mkdir -p /etc/alsa/conf.d
ln -sfn /usr/share/alsa/alsa.conf.d/50-pipewire.conf \
    /etc/alsa/conf.d/50-pipewire.conf
ln -sfn /usr/share/alsa/alsa.conf.d/99-pipewire-default.conf \
    /etc/alsa/conf.d/99-pipewire-default.conf

# Laptop stuff
if [ -d /sys/class/power_supply/BAT0 ] || ls /sys/class/power_supply/BAT* >/dev/null 2>&1; then
   enable_service tlp
fi


# TODO:
# - [ ] Video Accelleration (may need different paths based on graphics card)
# - [ ] ifconfig command whatever that is?
# - [ ] Nvidia potentially?
# - [ ] Check wifi fix for this computer
# - [ ] Remove packages not on list (later)

