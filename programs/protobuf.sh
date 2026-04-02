#!/bin/bash -e
printf " [ START ] Protobuf \n"
starttime=$(date +%s)
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
PROTOC_VERSION="$(jq -r '.APACHE_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if ! curl https://github.com/google/protobuf/releases/download/v"${PROTOC_VERSION}"/protoc-"${PROTOC_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".zip
then
    echo "Download failed! Exiting."
    exit 1
fi
unzip protoc-"${PROTOC_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".zip -o -d protoc3
sudo mv protoc3/bin/* /usr/local/bin/
sudo cp -r protoc3/include/. /usr/local/include/
sudo chown "${USER}" /usr/local/bin/protoc
sudo chown -R "${USER}" /usr/local/include/google
endtime=$(date +%s)
printf " [ DONE ] Protobuf ... %s seconds \n" "$((endtime-starttime))"
