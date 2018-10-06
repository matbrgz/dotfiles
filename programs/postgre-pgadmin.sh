#!/bin/bash -e
printf " [ START ] pgAdmin \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge pgadmin*
fi
sudo apt -y install pgadmin"${PGADMIN_VERSION}"
dpkg --get-selections | grep pgadmin"${PGADMIN_VERSION}"
endtime=$(date +%s)
printf " [ DONE ] pgAdmin ... %s seconds \n" "$((endtime-starttime))"
