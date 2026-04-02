#!/bin/bash -e
printf " [ START ] NetKit \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
NETKIT_VERSION="$(jq -r '.NETKIT_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
NETKITFS_VERSION="$(jq -r '.NETKITFS_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if ! curl http://wiki.netkit.org/download/netkit/netkit-"${NETKIT_VERSION}".tar.bz2
then
    echo "Download failed! Exiting."
    exit 1
fi
tar -xjSf netkit-"${NETKIT_VERSION}".tar.bz2
if ! curl http://wiki.netkit.org/download/netkit-filesystem/netkit-filesystem-i386-F"${NETKITFS_VERSION}".tar.bz2
then
    echo "Download failed! Exiting."
    exit 1
fi
tar -xjSf netkit-filesystem-i386-F"${NETKITFS_VERSION}".tar.bz2
if ! curl http://wiki.netkit.org/download/netkit-kernel/netkit-kernel-i386-K"${NETKIT_VERSION}".tar.bz2
then
    echo "Download failed! Exiting."
    exit 1
fi
tar -xjSf netkit-kernel-i386-K"${NETKIT_VERSION}".tar.bz2
{
    export NETKIT_HOME="${HOME}"/netkit
    export MANPATH=:${NETKIT_HOME}/man
    export PATH=${NETKIT_HOME}/bin:$PATH
} >> "${HOME}"/.bashrc
chmod a+x /netkit/check_configuration.sh
./netkit/check_configuration.sh
endtime=$(date +%s)
printf " [ DONE ] NetKit ... %s seconds \n" "$((endtime-starttime))"
