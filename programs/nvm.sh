#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
NVM_VERSION="$(jq -r '.NVM_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "NVM purge not implemented yet! Skipping."
fi
if ! curl https://raw.githubusercontent.com/creationix/nvm/v"${NVM_VERSION}"/install.sh | bash
then
	echo "NVM Download failed! Exiting."
	exit 1
fi
wait
bash
nvm -v
nvm install --lts
nvm use --lts
npm install -g yarn
yarn install leasot
echo "alias ss=\"script/server\"" >> "${HOME}"/.bash_aliases
