#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
RUBY_VERSION="$(jq -r '.RUBY_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
export $PATH:"${USER}"/.rvm/scripts/rvm
rvm install "${RUBY_VERSION}"
/bin/bash --login
rvm use "${RUBY_VERSION}"
echo "alias gtest=\"testrb test/integration/bundle_test.rb\"" >>"${HOME}"/.bash_aliases
