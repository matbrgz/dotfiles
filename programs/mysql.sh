#!/bin/bash -e
printf " [ START ] MySQL \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge mysql-server mysql-client
fi
sudo apt -y install mysql-server mysql-client
sudo usermod -d /var/lib/mysql/ mysql
printf "Press enter when asked for mysql password"
sudo mysql_secure_installation
dpkg --get-selections | grep mysql
endtime=$(date +%s)
printf " [ DONE ] MySQL ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.phpmyadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/mysql-phpmyadmin.sh
	wait
fi
