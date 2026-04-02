#!/bin/bash -e
printf " [ START ] Anaconda \n"
starttime=$(date +%s)
# Linux, Dawrin, BSD etc
HEADER_TYPE="$(uname -s)"
# Architeture x86_64 amd64
ARCHITECTURE_TYPE="$(uname -m)"
if ! curl https://repo.anaconda.com/archive/Anaconda"${ANACONDA_VERSION}"-"${HEADER_TYPE}"-"${ARCHITECTURE_TYPE}".sh | bash
then
    echo "Download failed! Exiting."
    exit 1
fi
wait
. "${HOME}"/.bashrc
endtime=$(date +%s)
printf " [ DONE ] Anaconda ... %s seconds \n" "$((endtime-starttime))"
