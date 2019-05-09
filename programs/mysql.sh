#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	sudo apt -y purge mysql-server mysql-client
fi
sudo apt -y install mysql-server mysql-client
sudo usermod -d /var/lib/mysql/ mysql
printf "Press enter when asked for mysql password"
sudo mysql_secure_installation
dpkg --get-selections | grep mysql
