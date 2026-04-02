#!/bin/bash -e
printf " [ START ] Mosh SSH \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge mosh
fi
sudo apt -y install perl protobuf-compiler libprotobuf-dev libncurses5-dev zlib1g-dev pkg-config
sudo add-apt-repository -y ppa:keithw/mosh
sudo apt -y update
sudo apt -y install mosh
dpkg --get-selections | grep mosh
endtime=$(date +%s)
printf " [ DONE ] Mosh SSH ... %s seconds \n" "$((endtime-starttime))"
