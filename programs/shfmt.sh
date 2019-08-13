#!/bin/bash
PREVIOUS_PWD="$1"
SHFMT_VERSION="$(jq -r '.SHFMT_VERSION' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi 
HEADER_TYPE="$(uname -s)"
if ! curl https://github.com/mvdan/sh/releases/download/v"${SHFMT_VERSION}"/shfmt_v"${SHFMT_VERSION}"_"${HEADER_TYPE}"_amd64 | bash; then
	echo "shfmt Download failed! Skipping."
	kill $$
fi