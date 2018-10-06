#!/bin/bash -e
printf " [ START ]  \n"
starttime=$(date +%s)
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
endtime=$(date +%s)
printf " [ DONE ] ... %s seconds \n" "$((endtime-starttime))"
