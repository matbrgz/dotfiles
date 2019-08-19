#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
nvm install --lts
nvm use --lts
echo "nvm use --lts" >>"${HOME}"/.bashrc
npm install -g yarn
echo "alias ss=\"script/server\"" >>"${HOME}"/.bash_aliases
