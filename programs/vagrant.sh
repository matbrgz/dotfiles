#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
ARCHITECTURE_TYPE="$(uname -m)"
VAGRANT_VERSION="$(jq -r '.VAGRANT_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge virtualbox* vagrant*
fi
if ! wget https://releases.hashicorp.com/vagrant/"${VAGRANT_VERSION}"/vagrant_"${VAGRANT_VERSION}"_"${ARCHITECTURE_TYPE,,}".deb
then
	echo "Download failed! Exiting."
	kill "$0"
fi
sudo dpkg -i vagrant_"${VAGRANT_VERSION}"_"${ARCHITECTURE_TYPE}".deb
defaultfolder="$(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
echo '
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
  export PATH="${PATH}:/mnt/c/Program Files/Oracle/VirtualBox"
  export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="${defaultfolder}"
  export VAGRANT_HOME="${HOME}/.vagrant.d"
' >> "${HOME}"/.bashrc
echo '
alias vup="vagrant up && vagrant ssh"
alias vupdate="vagrant box update"
alias vhalt="vagrant halt"
alias vdestroy="vagrant halt && vagrant destroy"
' >> "${HOME}"/.bash_aliases
