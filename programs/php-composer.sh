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
if ! curl https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer | \
	sudo php -- --install-dir=/usr/local/bin --filename=composer --quite
then
	echo "PHP Composer Download failed! Exiting."
	exit 1
fi
sudo chown -R "${USER}" ~/.composer/

if [ "$(jq -r '.laravel' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
	"${PREVIOUS_PWD}"/programs/php-laravel.sh
	wait
fi
