#!/bin/bash -e
printf " [ START ] Node Version Management \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
NVM_VERSION="$(jq -r '.NVM_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if ! curl https://raw.githubusercontent.com/creationix/nvm/v"${NVM_VERSION}"/install.sh | bash
then
	echo "Download failed! Exiting."
	exit 1
fi
wait
exec bash
nvm -v
nvm install node
nvm use node
npm install -g yarn
yarn install leasot
echo "alias ss=\"script/server\"" >> "${HOME}"/.bash_aliases
endtime=$(date +%s)
printf " [ DONE ] Node Version Management ... %s seconds \n" "$((endtime-starttime))"
