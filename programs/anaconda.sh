#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
ANACONDA_VERSION="$(jq -r '.ANACONDA_VERSION' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	echo "Anaconda purge not implemented yet! Skipping."
fi
if ! curl https://repo.anaconda.com/archive/Anaconda"${ANACONDA_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".sh | bash; then
	echo "Anaconda Download failed! Skipping."
	kill $$
fi
