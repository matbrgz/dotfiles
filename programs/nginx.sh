#!/bin/bash -e
printf "NGINX ... [ START ] \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge nginx
fi
sudo apt -y install nginx
dpkg --get-selections | grep nginx
endtime=$(date +%s)
printf " [ DONE ] NGINX ... %s seconds \n" "$((endtime-starttime))"
