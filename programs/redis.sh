#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == y ]; then
	sudo apt -y purge radis-server*
fi
sudo apt -y install redis-server
dpkg --get-selections | grep radis-server
