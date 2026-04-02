#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
RELEASE_VERSION="$(lsb_release -cs)"
ANACONDA_VERSION="$(jq -r '.RSTUDIO_VERSION' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ]; then
	sudo apt -y purge rbase*
fi
sudo apt update
sudo apt install -y gdebi-core gfortran libgdal-dev libgeos-dev libpng-dev
sudo apt-get install -y libjpeg62-dev libjpeg8-dev libcairo-dev libssl-dev
if ! curl https://download2.rstudio.org/server/"${RELEASE_VERSION}"/amd64/rstudio-server-"${RSTUDIO_VERSION}"-amd64.deb | bash; then
	echo "RStudio Download failed! Skipping."
	kill $$
fi
sudo gdebi rstudio-server-"${RSTUDIO_VERSION}"-amd64.deb
if ! sudo curl /etc/init.d/rstudio-server \
	-L "https://raw.githubusercontent.com/rstudio/rstudio/master/src/cpp/server/extras/init.d/debian/rstudio-server.in"; then
	echo "RStudio Server Service Download failed! Skipping."
	kill $$
fi
sudo chmod 777 /etc/init.d/rstudio-server
/etc/init.d/rstudio-server start
adduser rstudio
cd /usr/lib/rstudio-server/bin
./rsession --log-stderr 1
 
cat /var/log/syslog
cat /var/log/messages
cat /var/lib/rstudio-server/monitor/log/rstudio-server.log

cd "${HOME}"/tmp || return

{
    # RStudio Config
	export R_HOME=/usr/lib/R #important! LIB not BIN, BIN is a .sh file
    export R_DOC_DIR=/usr/share/R/doc
    export R_INCLUDE_DIR=/usr/share/R/include
    export R_SHARE_DIR=/usr/share/R/share
    export EDITOR=vscode

} >>"${HOME}"/.bashrc


