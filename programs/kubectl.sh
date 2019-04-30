#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
KUBECTL_VERSION="$(jq -r '.KUBECTL_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "KubeCTL purge not implemented yet! Skipping."
fi
# $(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
if ! curl -L https://storage.googleapis.com/kubernetes-release/release/v"${KUBECTL_VERSION}"/bin/"${HEADER_TYPE}"/"${ARCHITECTURE_TYPE}"/kubectl; then
	echo "KubeCTL Download failed! Exiting."
	kill "$0"
fi
if [ -d /usr/local/bin/kubectl ]; then
	sudo rm -f -R /usr/local/bin/kubectl
fi
mkdir -p /usr/local/bin/kubectl
chmod 777 /usr/local/bin/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
