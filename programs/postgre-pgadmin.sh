#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge pgadmin*
fi
sudo apt -y install pgadmin"${PGADMIN_VERSION}"
dpkg --get-selections | grep pgadmin"${PGADMIN_VERSION}"
