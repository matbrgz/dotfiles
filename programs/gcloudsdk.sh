#!/bin/bash -e
printf " [ START ] Google Cloud SDK \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
echo "deb http://packages.cloud.google.com/apt cloud-sdk-${RELEASE_VERSION} main" | \
	sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
if ! curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo apt -qq update
sudo apt -y install google-cloud-sdk
dpkg --get-selections | grep google-cloud-sdk
endtime=$(date +%s)
printf " [ DONE ] Google Cloud SDK ... %s seconds \n" "$((endtime-starttime))"
