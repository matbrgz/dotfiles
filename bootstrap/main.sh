#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	# Disable exit on non 0
	set +e
else
	# Enable exit on non 0
	set -e
fi
printf "\n [ START ] Version Control\n"
starttime=$(date +%s)
"${PREVIOUS_PWD}"/bootstrap/version.sh
endtime=$(date +%s)
printf " [ DONE ] Version Control ... %s seconds\n" "$((endtime-starttime))"
for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
	_jq() {
		echo "${row}" | base64 --decode | jq -r "${1}"
	}
	if [ "$(_jq '.installation')" == true ] ; then
		programname=$(echo _jq '.name')
		printf "\n [ START ] %s\n" "$($programname)"
		starttime=$(date +%s)
		"${PREVIOUS_PWD}"/programs/"$(_jq '.program')".sh || error=true
		wait
		if [ "${error}" == true ]; then
			printf "\n ****************************\n"
			printf " [ ERROR ] %s\n" "$($programname)"
			printf " ****************************\n"
		fi
		endtime=$(date +%s)
		printf " [ DONE ] %s ... %s seconds\n" "$($programname)" "$((endtime-starttime))"
	fi
done
