#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge phpmyadmin
fi
sudo /etc/init.d/mysql stop
sudo apt -y install phpmyadmin
sudo /etc/init.d/mysql start
dpkg --get-selections | grep phpmyadmin
defaultfolder="$(jq -r ".defaultfolder" "${PREVIOUS_PWD}"/bootstrap/settings.json)"
echo '' >> "${defaultfolder}"/phpmyadmin
