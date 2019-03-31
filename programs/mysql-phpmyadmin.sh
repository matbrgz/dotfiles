#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge phpmyadmin
fi
sudo /etc/init.d/mysql stop
sudo apt -y install phpmyadmin
sudo /etc/init.d/mysql start
dpkg --get-selections | grep phpmyadmin
defaultfolder="$(jq -r ".defaultfolder" "${PREVIOUS_PWD}"/bootstrap/settings.json)"
echo '' >> "${defaultfolder}"/phpmyadmin
