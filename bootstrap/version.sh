#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
sudo rm -f version.json
if ! curl https://raw.githubusercontent.com/MatheusRV/dotfiles/master/bootstrap/version.json --create-dirs -o "${PREVIOUS_PWD}"/bootstrap/version.json
then
	echo "Download failed downloading version control! Exiting."
	exit 1
fi
