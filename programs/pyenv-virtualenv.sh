#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
git clone https://github.com/pyenv/pyenv-virtualenv.git "$(pyenv root)"/plugins/pyenv-virtualenv
echo "eval $(pyenv virtualenv-init -)" >>~/.bash_profile
exec "$SHELL"
virtualenv -p /usr/bin/python"${PYTHON_VERSION}" venv
echo "alias venvstart=\"source ${VENV_PATH}/venv/bin/activate\"" >>"${HOME}"/.bash_aliases
source ${VENV_PATH}/venv/bin/activate
