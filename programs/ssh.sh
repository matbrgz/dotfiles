#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	set +e
else
	set -e
fi
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge openssh-server*
fi
sudo apt -y install openssh-server
sudo sed -i "/#PasswordAuthentication no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo service ssh --full-restart
sudo service ssh start
