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
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	sudo apt -y purge python-pip
	sudo python -m pip uninstall pip
fi
sudo apt -y install python-pip
pip install --upgrade pip
echo "export PATH=\"${HOME}/.local/bin:$PATH\"" >> "${HOME}"/.bashrc