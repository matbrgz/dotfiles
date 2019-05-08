#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "GCloudSDK purge not implemented yet! Skipping."
fi
echo "deb http://packages.cloud.google.com/apt cloud-sdk-${RELEASE_VERSION} main" |
	sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
if ! curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -; then
	echo "GCloudSDK Download failed! Exiting."
	kill $$
fi
sudo apt -qq update
sudo apt -y install google-cloud-sdk
dpkg --get-selections | grep google-cloud-sdk
