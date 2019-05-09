#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
HEADER_TYPE="$(uname -s)"
ARCHITECTURE_TYPE="$(uname -m)"
DOCKER_COMPOSE_VERSION="$(jq -r '.DOCKER_COMPOSE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "Docker Compose purge not implemented yet! Skipping."
fi
if ! sudo curl /usr/local/bin/docker-compose \
	-L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-${HEADER_TYPE}-${ARCHITECTURE_TYPE}"; then
	echo "Docker Compose Download failed! Skipping."
	kill $$
fi
sudo chmod +x /usr/local/bin/docker-compose
