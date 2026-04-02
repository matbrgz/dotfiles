#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
sudo apt -y install x11-apps
{
	# X11 Config
	DISPLAY=:0.0
    export DISPLAY
} >>"${HOME}"/.bashrc