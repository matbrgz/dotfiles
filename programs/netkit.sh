#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	set +e
else
	set -e
fi
NETKIT_VERSION="$(jq -r '.NETKIT_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
NETKITFS_VERSION="$(jq -r '.NETKITFS_VERSION' "${PREVIOUS_PWD}"/bootstrap/version.json)"
if [ "$(jq -r '.configurations.purge' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
	echo "NetKit purge not implemented yet! Skipping."
fi
if ! curl http://wiki.netkit.org/download/netkit/netkit-"${NETKIT_VERSION}".tar.bz2; then
	echo "NetKit part 1 Download failed! Exiting."
	kill $$
fi
tar -xjSf netkit-"${NETKIT_VERSION}".tar.bz2
if ! curl http://wiki.netkit.org/download/netkit-filesystem/netkit-filesystem-i386-F"${NETKITFS_VERSION}".tar.bz2; then
	echo "NetKit part 2 Download failed! Exiting."
	kill $$
fi
tar -xjSf netkit-filesystem-i386-F"${NETKITFS_VERSION}".tar.bz2
if ! curl http://wiki.netkit.org/download/netkit-kernel/netkit-kernel-i386-K"${NETKIT_VERSION}".tar.bz2; then
	echo "NetKit part 3 Download failed! Exiting."
	kill $$
fi
tar -xjSf netkit-kernel-i386-K"${NETKIT_VERSION}".tar.bz2
{
	#NetKit Config
	export NETKIT_HOME="${HOME}"/netkit
	export MANPATH=:${NETKIT_HOME}/man
	export PATH=${NETKIT_HOME}/bin:$PATH

} >>"${HOME}"/.bashrc
chmod a+x /netkit/check_configuration.sh
./netkit/check_configuration.sh
