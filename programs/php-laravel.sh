#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
composer global require "laravel/installer"
#TODO: Need refactory this if
if [ "$(jq -r '.programs[].mysql.instalation' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	printf "\n [ START ] Laravel Default MySQL Configuration\n"
	starttime=$(date +%s)
	echo " [ DOING ] Setting Laravel Default .env DB user on MySQL (user & db 'homestead', password 'secret')"
	mysql -u root -p -e "CREATE DATABASE homestead /*\!40100 DEFAULT CHARACTER SET utf8 */;"
	mysql -u root -p -e "CREATE USER homestead@localhost IDENTIFIED BY 'secret';"
	mysql -u root -p -e "GRANT ALL PRIVILEGES ON homestead.* TO 'homestead'@'localhost';"
	mysql -u root -p -e "FLUSH PRIVILEGES;"
	endtime=$(date +%s)
	printf " [ DONE ] Laravel Default MySQL Configuration ... %s seconds\n" "$((endtime - starttime))"
fi
