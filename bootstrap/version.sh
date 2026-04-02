#!/bin/bash -e
if ! curl https://raw.githubusercontent.com/MatheusRV/dotfiles/wsl/bootstrap/version.json --create-dirs -o "${PREVIOUS_PWD}"/bootstrap/version.json
then
    echo "Download failed! Exiting."
    exit 1
fi
