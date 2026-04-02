#!/bin/bash
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)"/plugins/pyenv-virtualenv
echo "eval $(pyenv virtualenv-init -)" >> ~/.bash_profile
source "${HOME}"/.bashrc
#virtualenv -p /usr/bin/python"${PYTHON_VERSION}" venv
echo "alias venvstart=\"source $VENV_PATH/venv/bin/activate\"" >> "${HOME}"/.bash_aliases
#source ${VENV_PATH}/venv/bin/activate
endtime=$(date +%s)
printf " [ DONE ] PyEnv-VirtualEnv ... %s seconds \n" "$((endtime-starttime))"
