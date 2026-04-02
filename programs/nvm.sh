#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
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
	kill "$0"
fi
wait
traphup() {
	$0 "$@" &
	exit 0
}
trap traphup HUP
nvm install --lts
nvm use --lts
npm install -g yarn
yarn install leasot
echo "alias ss=\"script/server\"" >>"${HOME}"/.bash_aliases
