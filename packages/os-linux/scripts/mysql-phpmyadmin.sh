#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	sudo apt -y purge phpmyadmin
fi
sudo /etc/init.d/mysql stop
sudo apt -y install phpmyadmin
sudo /etc/init.d/mysql start
dpkg --get-selections | grep phpmyadmin
defaultfolder="$(jq -r ".personal.defaultfolder" "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
echo '' >>"${defaultfolder}"/phpmyadmin
