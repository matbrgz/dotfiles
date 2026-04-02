#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
ANACONDA_VERSION="$(jq -r '.anaconda' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "Anaconda purge not implemented yet! Skipping."
fi
if ! curl https://repo.anaconda.com/archive/Anaconda"${ANACONDA_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".sh | bash
then
	echo "Anaconda Download failed! Skipping."
	kill "$0"
fi
wait
bash
