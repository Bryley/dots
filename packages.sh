#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

mapfile -t packages < <(
   sed 's/#.*//' "$script_dir/packages.txt" | awk 'NF'
)
mapfile -t services < <(
   sed 's/#.*//' "$script_dir/services.txt" | awk 'NF'
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

