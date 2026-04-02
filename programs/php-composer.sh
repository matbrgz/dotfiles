#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
if ! curl https://raw.githubusercontent.com/composer/getcomposer.org/1b137f8bf6db3e79a38a5bc45324414a6b1f9df2/web/installer |
	sudo php -- --install-dir=/usr/local/bin --filename=composer --quite; then
	echo "PHP Composer Download failed! Exiting."
	kill $$
fi
sudo chown -R "${USER}" ~/.composer/
