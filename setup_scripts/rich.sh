#!/bin/bash

RESET_COL="\033[0m"
OPTIONS_COL="\033[1;35m"
DEFAULT_COL="\033[0;36m"
ERR_COL="\033[1;31m"


prompt() {
    msg=$1
    default=$2

    while true; do
        printf "${msg} ${OPTIONS_COL}[y/n] ${DEFAULT_COL}(${default})${RESET_COL}: "

        read

        if [ "$REPLY" == "" ]; then
            REPLY=$default
        fi

        if [ "$REPLY" == "y" ]; then
            return 0
        elif [[ "$REPLY" == "n" ]]; then
            return 1
        fi
        error "'${DEFAULT_COL}$REPLY${ERR_COL}' is not a valid answer, please select '${OPTIONS_COL}y${ERR_COL}' or '${OPTIONS_COL}n${ERR_COL}'."
    done
}


error() {
    msg=$1
    echo -e "${ERR_COL}${msg}$RESET_COL"
}

info() {
    msg=$1
    echo -e "${OPTIONS_COL}$msg$RESET_COL"
}
