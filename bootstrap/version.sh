#!/bin/bash -e
sudo rm -f version.json
if ! curl https://raw.githubusercontent.com/MatheusRV/dotfiles/master/bootstrap/version.json --create-dirs -o "${PREVIOUS_PWD}"/bootstrap/version.json
then
	echo "Download failed downloading version control! Exiting."
	exit 1
fi
