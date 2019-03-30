#!/bin/bash -e
printf " [ START ] Azure CLI \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge azure-cli
fi
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ ${RELEASE_VERSION} main" | \
	sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 52E16F86FEE04B979B07E28DB02C46DF417A0893
if ! curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo apt -qq update
sudo apt -y install azure-cli
dpkg --get-selections | grep azure-cli
endtime=$(date +%s)
printf " [ DONE ] Azure CLI ... %s seconds \n" "$((endtime-starttime))"
