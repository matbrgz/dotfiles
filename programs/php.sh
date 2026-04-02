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
PHP_VERSION="$(jq -r '.PHP_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
APACHE_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	sudo apt -y purge php php*
fi
sudo add-apt-repository -y ppa:ondrej/php
sudo apt -qq update
sudo apt -y install php"${PHP_VERSION}" \
	php"${PHP_VERSION}"-gd \
	php"${PHP_VERSION}"-curl \
	php"${PHP_VERSION}"-mbstring \
	php"${PHP_VERSION}"-xml \
	php"${PHP_VERSION}"-pdo \
	php"${PHP_VERSION}"-json \
	php"${PHP_VERSION}"-zip \
	php"${PHP_VERSION}"-dev \
	mcrypt \
	libapache"${APACHE_VERSION}"-mod-php"${PHP_VERSION}"
dpkg --get-selections | grep php
endtime=$(date +%s)
printf " [ DONE ] php ... %s seconds \n" "$((endtime-starttime))"
"${PREVIOUS_PWD}"/programs/php-composer.sh
wait
