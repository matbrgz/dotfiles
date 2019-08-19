#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
	set +e
else
	set -e
fi
RUBY_VERSION="$(jq -r '.RUBY_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
export PATH="$PATH:$HOME/.rvm/bin"
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
rvm install "${RUBY_VERSION}"
/bin/bash --login
rvm use "${RUBY_VERSION}"
echo "alias gtest=\"testrb test/integration/bundle_test.rb\"" >>"${HOME}"/.bash_aliases
