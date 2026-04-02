#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
KUBERNETES_HELM_VERSION="$(jq -r '.KUBERNETES_HELM_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "Kubernetes Helm purge not implemented yet! Skipping."
fi
if ! curl -L https://storage.googleapis.com/kubernetes-helm/helm-v"${KUBERNETES_HELM_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".tar.gz; then
	echo "Kubernetes Helm Download failed! Exiting."
	kill $$
fi
if [ -d /usr/local/bin/helm ]; then
	sudo rm -f -R /usr/local/bin/helm
fi
mkdir -p /usr/local/bin/helm
chmod 777 /usr/local/bin/helm
tar -zxvf helm-v"${KUBERNETES_HELM_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".tar.gz
sudo mv "${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}"/helm /usr/local/bin/helm
