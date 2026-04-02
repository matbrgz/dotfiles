#!/bin/bash -e
printf " [ START ] Python pip \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge python-pip
	sudo python -m pip uninstall pip
fi
sudo apt -y install python-pip
pip install --upgrade pip
echo "export PATH=\"${HOME}/.local/bin:$PATH\"" >> "${HOME}"/.bashrc
endtime=$(date +%s)
printf " [ DONE ] Python pip ... %s seconds \n" "$((endtime-starttime))"
