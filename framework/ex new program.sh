#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
defaultfolder="$(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
DOCKER_COMPOSE_VERSION="$(jq -r '.DOCKER_COMPOSE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"/
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "Anaconda purge not implemented yet! Skipping."
fi
