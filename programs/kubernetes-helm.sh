#!/bin/bash -e
printf " [ START ] GoLang \n"
starttime=$(date +%s)
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
KUBERNETES_HELM_VERSION="$(jq -r '.KUBERNETES_HELM_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if ! curl -L https://storage.googleapis.com/kubernetes-helm/helm-v"${KUBERNETES_HELM_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".tar.gz
then
	echo "Download failed! Exiting."
	exit 1
fi
if [ -d /usr/local/bin/helm ]; then
	sudo rm -f -R /usr/local/bin/helm
fi
mkdir -p /usr/local/bin/helm
chmod 777 /usr/local/bin/helm
tar -zxvf helm-v"${KUBERNETES_HELM_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".tar.gz
sudo mv "${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}"/helm /usr/local/bin/helm
endtime=$(date +%s)
printf " [ DONE ] GoLang ... %s seconds \n" "$((endtime-starttime))"
