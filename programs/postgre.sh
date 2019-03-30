#!/bin/bash -e
printf " [ START ] Postgre \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge postgresql postgresql-*
fi
sudo apt -y install postgresql postgresql-common
dpkg --get-selections | grep postgre
endtime=$(date +%s)
printf " [ DONE ] Postgre ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.postgis' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/postgis.sh
	wait
fi
if [ "$(jq -r '.pgadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/pgadmin.sh
	wait
fi
