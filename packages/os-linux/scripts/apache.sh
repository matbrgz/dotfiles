#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
      set +e
else
      set -e
fi
APACHE_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
      sudo apt -y purge apache"${APACHE_VERSION}"*
fi
sudo apt -y install apache"${APACHE_VERSION}"
dpkg --get-selections | grep apache