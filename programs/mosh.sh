#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	sudo apt -y purge mosh
fi
sudo apt -y install perl protobuf-compiler libprotobuf-dev libncurses5-dev zlib1g-dev pkg-config
sudo add-apt-repository -y ppa:keithw/mosh
sudo apt -qq update
sudo apt -y install mosh
dpkg --get-selections | grep mosh
