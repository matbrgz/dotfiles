#!/bin/bash -e
printf " [ START ] Redis \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge radis-server*
fi
sudo apt -y install redis-server
dpkg --get-selections | grep radis-server
endtime=$(date +%s)
printf " [ DONE ] Redis ... %s seconds \n" "$((endtime-starttime))"
