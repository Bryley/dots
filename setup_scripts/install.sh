#!/bin/bash

source $DOT_DIR/setup_scripts/rich.sh

prompt "Do you want to install all the nessessary packages?" "n"
if [ "$?" != 0 ]; then
    info "Skipped installing packages"
    exit 0
fi

if [ "$(cat /etc/os-release | grep -e ^ID | awk -F '=' '{print $2}')" != "arch" ]; then
    error "The install script only works on Arch based distros"
    exit 1
fi

# TODO install the nvidia-git instead if nvidia is detected
# (script will change this to hyprland-nvidia-git if nvidia card is detected)

echo "TODO"
