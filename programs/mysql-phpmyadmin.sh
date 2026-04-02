#!/bin/bash -e
printf " [ START ] phpMyAdmin \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge phpmyadmin
fi
sudo /etc/init.d/mysql stop
sudo apt -y install phpmyadmin
sudo /etc/init.d/mysql start
dpkg --get-selections | grep phpmyadmin
defaultfolder="$(jq -r ".defaultfolder" "${PREVIOUS_PWD}"/bootstrap/settings.json)"
echo '' >> "${defaultfolder}"/phpmyadmin
endtime=$(date +%s)
printf " [ DONE ] phpMyAdmin ... %s seconds \n" "$((endtime-starttime))"
