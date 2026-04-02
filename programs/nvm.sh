#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
NVM_VERSION="$(jq -r '.NVM_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "NVM purge not implemented yet! Skipping."
fi
if ! curl https://raw.githubusercontent.com/creationix/nvm/v"${NVM_VERSION}"/install.sh | bash; then
	echo "NVM Download failed! Exiting."
	kill $$
fi
wait
