#!/bin/bash -e
printf " [ START ] .NET Mono  \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge mono*
fi
sudo echo "deb https://download.mono-project.com/repo/ubuntu stable-${RELEASE_VERSION} main" | \
      sudo tee /etc/apt/sources.list.d/mono-official-stable.list
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
sudo apt -qq update
sudo apt -y install mono-devel
dpkg --get-selections | grep mono
endtime=$(date +%s)
printf " [ DONE ] .NET Mono ... %s seconds \n" "$((endtime-starttime))"
