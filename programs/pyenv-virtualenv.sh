#!/bin/bash -e
printf " [ START ] PyEnv-VirtualEnv \n"
starttime=$(date +%s)
git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)"/plugins/pyenv-virtualenv
echo "eval $(pyenv virtualenv-init -)" >> ~/.bash_profile
source "${HOME}"/.bashrc
#virtualenv -p /usr/bin/python"${PYTHON_VERSION}" venv
echo "alias venvstart=\"source $VENV_PATH/venv/bin/activate\"" >> "${HOME}"/.bash_aliases
#source ${VENV_PATH}/venv/bin/activate
endtime=$(date +%s)
printf " [ DONE ] PyEnv-VirtualEnv ... %s seconds \n" "$((endtime-starttime))"
