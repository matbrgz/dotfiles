#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
    set +e
else
    set -e
fi
npm install -g localtunnel
sudo chmod a+x "${PREVIOUS_PWD}"/programs/tools-and-services/localtunnel-service.sh
sudo mv "${PREVIOUS_PWD}"/programs/tools-and-services/localtunnel-service.sh /etc/init.d/localtunnel
update-rc.d localtunnel defaults
