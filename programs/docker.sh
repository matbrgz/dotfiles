#!/bin/bash -e
printf " [ START ] Docker \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge docker*
fi
if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${RELEASE_VERSION} stable"
sudo apt-key fingerprint 0EBFCD88
sudo apt -qq update
sudo apt -y install docker-ce
dpkg --get-selections | grep docker
sudo groupadd docker
sudo usermod -aG docker "${USER}"
docker -H localhost:2375 images
echo "export DOCKER_HOST=\"tcp://0.0.0.0:2375\"" >> "${HOME}"/.bashrc
source "${HOME}"/.bashrc
endtime=$(date +%s)
printf " [ DONE ] Docker ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.dockercompose' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/docker-compose.sh
	wait
fi
