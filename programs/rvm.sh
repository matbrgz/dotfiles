#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
#RUBY_VERSION="$(jq -r '.RUBY_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge ruby* rvm*
fi
# TODO: Fix 'failed: IPC connect call failed gpg: keyserver receive failed: No dirmngr' on install rvm key.
sudo apt -y install dirmngr
gpg-connect-agent reloadagent /bye
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
if ! curl -sSL https://get.rvm.io | bash -s stable
then
	echo "Download failed! Exiting."
	kill "$0"
fi
wait
source "${HOME}"/.bashrc
#rvm install "${RUBY_VERSION}"
#/bin/bash --login
#rvm use "${RUBY_VERSION}"
echo "alias gtest=\"testrb test/integration/bundle_test.rb\"" >> "${HOME}"/.bash_aliases
