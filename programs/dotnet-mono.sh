#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge mono*
fi
sudo echo "deb https://download.mono-project.com/repo/ubuntu stable-${RELEASE_VERSION} main" | \
	sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sudo apt -qq update
sudo apt -y install mono-devel
dpkg --get-selections | grep mono
