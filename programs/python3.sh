#!/bin/bash -e
printf " [ START ] Python3 \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
PYTHON_VERSION="$(jq -r '.PYTHON_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge python3 python3-*
fi
sudo apt -y install software-properties-common
sudo add-apt-repository -y ppa:jonathonf/python-"${PYTHON_VERSION}"
sudo apt -qq update
sudo apt -y install python"${PYTHON_VERSION}" python"${PYTHON_VERSION}"-dev
sudo apt -y install \
    libgfortran3 \
    python-qt4 \
    python3-tk \
    keychain
echo "alias pstart=\"python -m SimpleHTTPServer 4000\"" >> "${HOME}"/.bash_aliases
endtime=$(date +%s)
printf " [ DONE ] Python3 ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.pythonpip' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/python-pip.sh
    wait
fi
if [ "$(jq -r '.pyenv' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/pyenv.sh
    wait
fi
