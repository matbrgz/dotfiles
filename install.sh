#!/bin/bash
{ # this ensures the entire script is downloaded #
	clear
	PREVIOUS_PWD="${PWD}"
	if [ -d "${HOME}"/tmp ]; then
		sudo rm -f -R "${HOME}"/tmp
	fi
	mkdir -p "${HOME}"/tmp
	cd "${HOME}"/tmp || return
	JSON_STRING=$( jq -n --arg pwd "${PREVIOUS_PWD}" '{pwd: $pwd}' )
	echo "${JSON_STRING}" >> "${HOME}"/tmp/pwd.json
	if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
		# Disable exit on non 0
		set +e
	else
		# Enable exit on non 0
		set -e
	fi
	if [[ ! "$(uname -r)" =~ "Microsoft$" ]]; then
		starttotaltime=$(date +%s)
		printf "\n Welcome to Windows Subsystem Linux Bootstrap Script\n"
		echo " ( PRESS KEY '1' FOR EXPRESS INSTALL )"
		echo " ( PRESS KEY '2' FOR CUSTOM INSTALL )"
		echo " ( PRESS KEY '3' FOR SOFTWARE INSTALL )"
		printf "\n Option: "
		read -r instalationtype
		printf "\n First time runing script? (Y/n): "
		read -r firstrun
		if [ -z "${firstrun}" ] || [ "${firstrun}" == Y ] || [ "${firstrun}" == y ]; then
			printf "\n [ START ] Update & Upgrade\n"
			starttime=$(date +%s)
			sudo apt -qq update && sudo apt -y upgrade && sudo apt -y dist-upgrade
			endtime=$(date +%s)
			printf " [ DONE ] Update & Upgrade ... %s seconds\n" "$((endtime-starttime))"
			printf "\n [ START ] Common Requirements\n"
			starttime=$(date +%s)
			apps=(
				software-properties-common
				build-essential
				apt-transport-https
				moreutils
				curl
				jq
				unzip
				libssl-dev
				ca-certificates
			)
			sudo apt -y install "${apps[@]}"
			endtime=$(date +%s)
			printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime-starttime))"
			printf "\n [ START ] Alias\n"
			starttime=$(date +%s)
			"${PREVIOUS_PWD}"/configurations/alias.sh
			"${PREVIOUS_PWD}"/configurations/alias-wsl.sh
			endtime=$(date +%s)
			printf " [ DONE ] Alias ... %s seconds\n" "$((endtime-starttime))"
		else
			printf "\n [ START ] Fix Possible Erros\n"
			starttime=$(date +%s)
			sudo apt --fix-broken install
			sudo dpkg --configure -a
			endtime=$(date +%s)
			printf " [ DONE ] Fix Possible Erros ... %s seconds\n" "$((endtime-starttime))"
		fi
		if [ "${instalationtype}" == 1 ]; then
			printf "\n [ START ] Software Instalation List\n"
			starttime=$(date +%s)
			for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
				_jq() {
					echo "${row}" | base64 --decode | jq -r "${1}"
				}
				if [ "$(_jq '.installation')" == true ]; then
					echo " $(_jq '.name'): $(_jq '.installation')"
				fi
			done
			endtime=$(date +%s)
			printf " [ DONE ] Software Instalation List ... %s seconds\n" "$((endtime-starttime))"
			sleep 3
		elif [ "${instalationtype}" == 2 ]; then
			printf "\n Default Dev Folder (Default for WSL: '/mnt/c/Dev'): "
			read -r defaultfolder
			if [ -z "${defaultfolder}" ]; then
				defaultfolder=/mnt/c/Dev
				if [ ! -d "${defaultfolder}" ]; then
					mkdir /mnt/c/Dev
				fi
				printf "/mnt/c/Dev"
			else
				if [ ! -d "${defaultfolder}" ]; then
					echo ${defaultfolder}
					mkdir ${defaultfolder}
				fi
			fi
			for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
				_jq() {
					echo "${row}" | base64 --decode | jq -r "${1}"
				}
				programvariable=$(_jq '.program')
				programdefault=$(_jq '.default')
				if [ "$programdefault" == true ]; then
					defaultoption="(Y/n)"
				else
					defaultoption="(y/N)"
				fi
				printf "\n Install %s %s: " "$(_jq '.name')" "$defaultoption"
				read -r "$programvariable"
				if [ "$programvariable" == Y ] || [ "$programvariable" == y ]; then
					export "$programvariable"=true
				elif [ -z "$programvariable" ]; then
					export "$programvariable"="$programdefault"
				else
					export "$programvariable"=false
				fi
				echo "$programvariable"
				echo "${!programvariable}"
				jq '."$programvariable".installation = ""${!programvariable}""' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
			done
		elif [ "${instalationtype}" == 3 ]; then
			printf "\n Type software name: "
			read -r program
			## TODO: Search for program name, to make sure that it exist.
			export "${program,,}"=true
			sudo sed -i "/\"${program,,}\": \"false\"/c\"${program,,}\": \"true\"" "${PREVIOUS_PWD}"/bootstrap/settings.json
		fi
		"${PREVIOUS_PWD}"/bootstrap/main.sh
		wait
		"${PREVIOUS_PWD}"/configurations/bashrc.sh &
		wait
		"${PREVIOUS_PWD}"/configurations/personal.sh &
		wait
		printf "\n [ START ] Common Requirements\n"
		starttime=$(date +%s)
		apps=(
			htop
			tmux
			shellcheck
		)
		sudo apt -y install "${apps[@]}"
		endtime=$(date +%s)
		printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime-starttime))"
		printf "\n [ START ] Cleaning\n"
		starttime=$(date +%s)
		sudo apt -y autoremove && sudo apt -y autoclean && sudo apt -y clean
		endtime=$(date +%s)
		printf " [ DONE ] Cleaning ... %s seconds\n" "$((endtime-starttime))"
		cd "${PREVIOUS_PWD}" || return
		sudo rm -R -f "${HOME}"/tmp
		endtotaltime=$(date +%s)
		printf "\n Total Time ... %s seconds\n" "$((endtotaltime-starttotaltime))"
	else
		printf 'Not Implemented'
		exit 1
	fi
} # this ensures the entire script is downloaded #
