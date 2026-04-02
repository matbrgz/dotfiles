#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
DOTNET_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge dotnet*
fi
sudo echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-${RELEASE_VERSION}-prod ${RELEASE_VERSION} main" | \
	sudo tee /etc/apt/sources.list.d/dotnetdev.list
if ! curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
then
	echo "Download failed! Exiting."
	kill "$0"
fi
sudo apt -qq update
sudo apt -y install dotnet-sdk-"${DOTNET_VERSION}"
dpkg --get-selections | grep dotnet
