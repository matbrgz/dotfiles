#!/bin/bash -e
printf " [ START ] Kubenetes CTL \n"
starttime=$(date +%s)
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
KUBECTL_VERSION="$(jq -r '.KUBECTL_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"

# $(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)
if ! curl -L https://storage.googleapis.com/kubernetes-release/release/v"${KUBECTL_VERSION}"/bin/"${HEADER_TYPE}"/"${ARCHITECTURE_TYPE}"/kubectl
then
	echo "Download failed! Exiting."
	exit 1
fi
if [ -d /usr/local/bin/kubectl ]; then
	sudo rm -f -R /usr/local/bin/kubectl
fi
mkdir -p /usr/local/bin/kubectl
chmod 777 /usr/local/bin/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
endtime=$(date +%s)
printf " [ DONE ] Kubenetes CTL ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.kuberneteshelm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/kubernetes-helm.sh
	wait
fi
