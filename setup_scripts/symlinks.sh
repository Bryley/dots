#!/bin/bash

DOT_DIR=$HOME/dots

source $DOT_DIR/setup_scripts/rich.sh

if [[ -z $XDG_CONFIG_HOME ]]; then
    CONFIG_FOLDER=$HOME/.config
else
    CONFIG_FOLDER=$XDG_CONFIG_HOME
fi

# Inital check
for config in $DOT_DIR/configs/*/; do
    link_path=$CONFIG_FOLDER/$(basename $config)

    if [ ! -L $link_path ] && [ -d $link_path ]; then
        error "Config directory '$link_path' already exists"
        prompt "Do you want to delete this directory and replace it with a symlink?" "n"
        if [ "$?" != 0 ]; then
            error "Exiting"
            exit 1
        fi
        rm -rf $link_path
    fi
done

for config in $DOT_DIR/configs/*/; do
    link_path=$CONFIG_FOLDER/$(basename $config)
    rm $link_path &> /dev/null
    ln -sf $config $link_path
done

# Setup .zshrc paths
echo -e "ZDOTDIR=$CONFIG_FOLDER/zsh\nskip_global_compinit=1" > $HOME/.zshenv
