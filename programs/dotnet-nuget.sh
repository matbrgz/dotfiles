#!/bin/bash -e
printf " [ START ] .NET NuGET  \n"
starttime=$(date +%s)
if ! curl /usr/local/bin/nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
then
	echo "Download failed! Exiting."
	exit 1
fi
sudo chmod 755 /usr/local/bin/nuget.exe
endtime=$(date +%s)
printf " [ DONE ] .NET NuGET ... %s seconds \n" "$((endtime-starttime))"
