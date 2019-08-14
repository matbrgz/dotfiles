#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
    set +e
else
    set -e
fi
port="$(jq -r '.programs[] | select(.program=="yarn-localtunnel").port' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
hostname="$(jq -r '.programs[] | select(.program=="yarn-localtunnel").hostname' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
yarn global add localtunnel
sudo chmod a+x "${PREVIOUS_PWD}"/programs/tools-and-services/localtunnel-service.sh
sudo cp "${PREVIOUS_PWD}"/programs/tools-and-services/localtunnel-service.sh /etc/init.d/localtunnel
sudo sed -i "/lt --port 2200 -s matheusrv;/c\lt --port ${port} -s ${hostname};" /etc/init.d/localtunnel

update-rc.d localtunnel defaults
