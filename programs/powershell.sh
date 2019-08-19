#!/bin/bash
PREVIOUS_PWD="${PWD}"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -rs)"
POWERSHELL_VERSION="$(jq -r '.POWERSHELL_VERSION' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == y ]; then
	sudo apt -y purge powershell
fi
if ! curl https://github.com/PowerShell/PowerShell/releases/download/v"${POWERSHELL_VERSION}"/powershell_"${POWERSHELL_VERSION}"-1.ubuntu."${RELEASE_VERSION}"_amd64.deb -o powershell_"${POWERSHELL_VERSION}".ubuntu."${RELEASE_VERSION}"_amd64.deb && dpkg -i powershell_"${POWERSHELL_VERSION}".ubuntu."${RELEASE_VERSION}"_amd64.deb; then
	echo "Powershell Download failed! Skipping."
	kill $$
fi
sudo apt install -yf
