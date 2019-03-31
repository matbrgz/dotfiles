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
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge mosh
fi
sudo apt -y install perl protobuf-compiler libprotobuf-dev libncurses5-dev zlib1g-dev pkg-config
sudo add-apt-repository -y ppa:keithw/mosh
sudo apt -qq update
sudo apt -y install mosh
dpkg --get-selections | grep mosh

