#!/bin/bash -e
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
defaultfolder="$(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ ! -z "${defaultfolder}" ] ; then
	#Configuring ~/.bashrc
	echo "cd ${defaultfolder}" >> "${HOME}"/./bashrc
fi
