#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(dpkg --print-architecture)"
GOLANG_VERSION="$(jq -r '.GOLANG_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo rm -f -R /usr/local/go
	sudo rm -f -R /usr/local/.go
	sudo rm -rf "${HOME}"/.go/
	sudo rm -rf "${HOME}"/go/
	sed -i '/# GoLang/d' "${HOME}"/.bashrc
	sed -i '/export GOROOT/d' "${HOME}"/.bashrc
	sed -i '/:$GOROOT/d' "${HOME}"/.bashrc
	sed -i '/export GOPATH/d' "${HOME}"/.bashrc
	sed -i '/:$GOPATH/d' "${HOME}"/.bashrc
fi
if [ -d /usr/local/go ] || [ -d "${HOME}"/go ] ; then
	echo "The 'go' or '.go' directories already exist. Exiting."
	kill "$0"
else
	sudo mkdir -p /usr/local/go
	sudo chmod 777 /usr/local/go
	sudo mkdir -p "${HOME}"/go "${HOME}"/go/{src,pkg,bin,out}
	sudo chmod 777 "${HOME}"/go "${HOME}"/go/src "${HOME}"/go/pkg "${HOME}"/go/bin "${HOME}"/go/out
fi
if ! sudo wget https://dl.google.com/go/go"${GOLANG_VERSION,,}"."${HEADER_TYPE,,}"-"${ARCHITECTURE_TYPE,,}".tar.gz
then
	echo "GoLang Download failed! Exiting."
	kill "$0"
fi
sudo tar -C "/usr/local" -xzf go"${GOLANG_VERSION,,}"."${HEADER_TYPE,,}"-"${ARCHITECTURE_TYPE,,}".tar.gz
{
	export GOBIN=${HOME}/go/bin
	export PATH=$PATH:/usr/local/go/bin:${HOME}/go
} >> "${HOME}"/.bashrc
