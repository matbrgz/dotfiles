#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
DOCKER_COMPOSE_VERSION="$(jq -r '.DOCKER_COMPOSE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "Docker Compose purge not implemented yet! Skipping."
fi
if ! sudo curl /usr/local/bin/docker-compose \
	-L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${HEADER_TYPE}-${ARCHITECTURE_TYPE}"
then
	echo "Docker Compose Download failed! Skipping."
	exit 1
fi
sudo chmod +x /usr/local/bin/docker-compose