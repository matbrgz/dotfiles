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
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "GCloudSDK purge not implemented yet! Skipping."
fi
echo "deb http://packages.cloud.google.com/apt cloud-sdk-${RELEASE_VERSION} main" | \
	sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
if ! curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
then
	echo "GCloudSDK Download failed! Exiting."
	exit 1
fi
sudo apt -qq update
sudo apt -y install google-cloud-sdk
dpkg --get-selections | grep google-cloud-sdk
