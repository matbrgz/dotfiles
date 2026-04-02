#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ]; then
	sudo apt -y purge docker*
fi
if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; then
	echo "Docker Download failed! Skipping."
	kill "$0"
fi
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu ${RELEASE_VERSION} stable"
sudo apt-key fingerprint 0EBFCD88
sudo apt -qq update
sudo apt -y install docker-ce
dpkg --get-selections | grep docker
sudo groupadd docker
sudo usermod -aG docker "${USER}" || true
docker -H localhost:2375 images
echo "export DOCKER_HOST=\"tcp://0.0.0.0:2375\"" >>"${HOME}"/.bashrc
bash
