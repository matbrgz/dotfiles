#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "NuGet purge not implemented yet! Skipping."
fi
if ! curl /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe; then
	echo "NuGet Download failed! Exiting."
	kill $$
fi
sudo chmod 755 /usr/local/bin/nuget.exe
