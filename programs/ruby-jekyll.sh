#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
gem install jekyll bundler
echo "alias jstart=\"bundle exec jekyll serve --watch\"" >>"${HOME}"/.bash_aliases
