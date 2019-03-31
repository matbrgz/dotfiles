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
composer global require "laravel/installer"
endtime=$(date +%s)
printf " [ DONE ] Laravel ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.mysql' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == n ] ; then
	printf " [ START ] Laravel Default MySQL Configuration \n"
	starttime=$(date +%s)
	echo " [ DOING ] Setting Laravel Default .env DB user on MySQL (user & db 'homestead', password 'secret')"
	mysql -u root -p -e "CREATE DATABASE homestead /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p -e "CREATE USER homestead@localhost IDENTIFIED BY 'secret';"
	mysql -u root -p -e "GRANT ALL PRIVILEGES ON homestead.* TO 'homestead'@'localhost';"
	mysql -u root -p -e "FLUSH PRIVILEGES;"
	endtime=$(date +%s)
	printf " [ DONE ] Laravel Default MySQL Configuration ... %s seconds \n" "$((endtime-starttime))"
fi
