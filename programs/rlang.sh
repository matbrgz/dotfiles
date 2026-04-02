#!/bin/bash -e
printf " [ START ] R \n"
starttime=$(date +%s)
# Bionic, Xenial, Trusty
RELEASE_VERSION="$(lsb_release -cs)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
  sudo apt -y purge rbase*
fi
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9
sudo add-apt-repository "deb [arch=amd64,i386] https://cran.rstudio.com/bin/${HEADER_TYPE}/ubuntu ${RELEASE_VERSION}/"
sudo apt -y install r-base
sudo -i R
endtime=$(date +%s)
printf " [ DONE ] R ... %s seconds \n" "$((endtime-starttime))"
