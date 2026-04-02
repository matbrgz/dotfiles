#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(dpkg --print-architecture)"
GOLANG_VERSION="$(jq -r '.GOLANG_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	echo "GoLang purge not implemented yet! Skipping."
fi
if [ -d /usr/local/go ] || [ -d "${HOME}"/go ]; then
	echo "The 'go' or '.go' directories already exist. Exiting."
	kill $$
else
	sudo mkdir -p /usr/local/go
	sudo chmod 777 /usr/local/go
	sudo mkdir -p "${HOME}"/go "${HOME}"/go/{src,pkg,bin,out}
	sudo chmod 777 "${HOME}"/go "${HOME}"/go/src "${HOME}"/go/pkg "${HOME}"/go/bin "${HOME}"/go/out
fi
if ! sudo wget https://dl.google.com/go/go"${GOLANG_VERSION,,}"."${HEADER_TYPE,,}"-"${ARCHITECTURE_TYPE,,}".tar.gz; then
	echo "GoLang Download failed! Exiting."
	kill $$
fi
sudo tar -C "/usr/local" -xzf go"${GOLANG_VERSION,,}"."${HEADER_TYPE,,}"-"${ARCHITECTURE_TYPE,,}".tar.gz
{
	#Go Lang Config
	export GOBIN=${HOME}/go/bin
	export PATH=${PATH}:/usr/local/go/bin:${HOME}/go

} >>"${HOME}"/.bashrc
