#!/bin/bash

DOT_DIR=$(dirname $(readlink -f ${BASH_SOURCE[0]}))

source $DOT_DIR/scripts/rich.sh

C_PURP="\033[35m"
C_WHITE="\033[37m"
echo -e " ${C_PURP}╭────────────────────────────────────╮"
echo -e " ${C_PURP}│ ${C_WHITE}Setup script for Bryley's Dotfiles ${C_PURP}│"
echo -e " ${C_PURP}╰────────────────────────────────────╯\033[0m"
echo -e ""

# echo -e "We firstly need to install all the nessessary Arch packages to get the dotfiles up and running"
bash $DOT_DIR/scripts/install.sh
