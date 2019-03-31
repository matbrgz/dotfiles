#!/bin/bash 
debug="$(jq -r '.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
if [ "${debug}" == true ]; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
# Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"
