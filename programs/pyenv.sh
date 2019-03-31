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
git clone https://github.com/pyenv/pyenv.git "${HOME}"/.pyenv
{
	export PYENV_ROOT="${HOME}/.pyenv"
	export PATH="${PYENV_ROOT}/bin:${PATH}"
	if command -v pyenv 1>/dev/null 2>&1; then
		eval "$(pyenv init -)"
	fi
} >> ~/.bashrc
source "${HOME}"/.bashrc
#pyenv install "${PYTHON_VERSION}"
source "${HOME}"/.bashrc
dpkg --get-selections | grep python
endtime=$(date +%s)
printf " [ DONE ] PyEnv ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.pyenvvirtualenv' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/pyenv-virtualenv.sh
	wait
fi
