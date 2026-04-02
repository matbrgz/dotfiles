#!/bin/bash -e
printf " [ START ] .NET \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
DOTNET_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge dotnet*
fi
sudo echo "deb [arch=amd64] https://packages.microsoft.com/repos/microsoft-ubuntu-${RELEASE_VERSION}-prod ${RELEASE_VERSION} main" | \
	sudo tee /etc/apt/sources.list.d/dotnetdev.list
if ! curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo apt -qq update
sudo apt -y install dotnet-sdk-"${DOTNET_VERSION}"
dpkg --get-selections | grep dotnet
endtime=$(date +%s)
printf " [ DONE ] .NET ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.dotnetnuget' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/dotnet-nuget.sh
	wait
fi
if [ "$(jq -r '.dotnetmono' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/dotnet-mono.sh
	wait
fi
