#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge azure-cli
fi
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ ${RELEASE_VERSION} main" | \
	sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
if ! curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
then
	echo "Azure CLI Download failed! Skipping."
	exit 1
fi
sudo apt -qq update
sudo apt -y install azure-cli
dpkg --get-selections | grep azure-cli
