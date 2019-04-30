#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
MONGO_VERSION="$(jq -r '.MONGO_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"/
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "MongoDB purge not implemented yet! Skipping."
fi
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu ${RELEASE_VERSION}/mongodb-org/${MONGO_VERSION} multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-"${MONGO_VERSION}".list
sudo apt -qq update
sudo apt -y install mongodb-org
echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-org-shell hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections
