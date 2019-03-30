#!/bin/bash -e
printf " [ START ] Docker Compose \n"
starttime=$(date +%s)
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
DOCKER_COMPOSE_VERSION="$(jq -r '.DOCKER_COMPOSE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if ! sudo curl /usr/local/bin/docker-compose \
	-L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${HEADER_TYPE}-${ARCHITECTURE_TYPE}"
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo chmod +x /usr/local/bin/docker-compose
endtime=$(date +%s)
printf " [ DONE ] Docker Compose ... %s seconds \n" "$((endtime-starttime))"
