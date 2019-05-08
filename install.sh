#!/bin/bash
{ # this ensures the entire script is downloaded #
	starttotaltime=$(date +%s)
	clear && clear
	printf "\n Welcome to Windows Subsystem Linux Bootstrap Script\n
 Initializating script, please waiting until program configure itself.
 This may take a few minutes and you will be prompted for the password
 to elevate the user's permission.\n"
	printf "\n [ START ] Configuring System Run\n"
	starttime=$(date +%s)
	PREVIOUS_PWD="${PWD}"
	if [ -d "${HOME}"/tmp ]; then
		sudo rm -f -R "${HOME}"/tmp
	fi
	mkdir -p "${HOME}"/tmp
	cd "${HOME}"/tmp && echo "cd ${HOME}/tmp" || return
	JSON_STRING=$(jq -n --arg pwd "${PREVIOUS_PWD}" '{pwd: $pwd}')
	echo "${JSON_STRING}" >>"${HOME}"/tmp/pwd.json
	sudo apt -qq update
	endtime=$(date +%s)
	printf " [ DONE ] Configuring System Run ... %s seconds\n" "$((endtime - starttime))"
	printf "\n [ START ] Instaling Major Requirements\n"
	starttime=$(date +%s)
	trap '' 2
	git clone https://github.com/molovo/lumberjack
 	sudo mv lumberjack/lj /usr/local/bin
	lj --file "${PREVIOUS_PWD}"/dotfiles.log --level debug
	chmod +x "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh
	sudo cp "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh /usr/local/bin/chkinstall
	sudo apt -y install jq moreutils
	if [ ! -n "$(command -v jq)" ] || [ ! -n "$(command -v sponge)" ]; then
		kill $$
	fi
	trap 2
	endtime=$(date +%s)
	printf " [ DONE ] Instaling Major Requirements ... %s seconds\n" "$((endtime - starttime))"
	printf "\n ( PRESS KEY '1' FOR EXPRESS INSTALL )
 ( PRESS KEY '2' FOR CUSTOM INSTALL )\n
 Option: "
	read -r instalationtype
	printf "\n Enable Debug Mode (y/N): "
	read -r debugmode
	if [ "$debugmode" == Y ] || [ "$debugmode" == y ]; then
		debugmode=true
	else
		debugmode=false
	fi
	jq '.configurations.debug = "'"${debugmode}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
	unset debugmode
	if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ]; then
		set +e
	else
		set -e
	fi
	printf "\n First time runing script? (Y/n): "
	read -r firstrun
	if [ -z "${firstrun}" ] || [ "${firstrun}" == Y ] || [ "${firstrun}" == y ]; then
		printf "\n [ START ] Update & Upgrade\n"
		starttime=$(date +%s)
		sudo apt -y upgrade && sudo apt -y dist-upgrade
		endtime=$(date +%s)
		printf " [ DONE ] Update & Upgrade ... %s seconds\n" "$((endtime - starttime))"
		printf "\n [ START ] Common Requirements\n"
		starttime=$(date +%s)
		apps=(
			software-properties-common
			build-essential
			apt-transport-https
			curl
			unzip
			libssl-dev
			ca-certificates
		)
		sudo apt -y install "${apps[@]}"
		unset apps
		endtime=$(date +%s)
		printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime - starttime))"
		printf "\n [ START ] Alias\n"
		starttime=$(date +%s)
		"${PREVIOUS_PWD}"/configurations/alias.sh
		wait
		endtime=$(date +%s)
		printf " [ DONE ] Alias ... %s seconds\n" "$((endtime - starttime))"
	elif [ "${firstrun}" == N ] || [ "${firstrun}" == n ]; then
		printf "\n [ START ] Fix Possible Erros\n"
		starttime=$(date +%s)
		sudo apt --fix-broken install
		sudo dpkg --configure -a
		endtime=$(date +%s)
		printf " [ DONE ] Fix Possible Erros ... %s seconds\n" "$((endtime - starttime))"
		printf "\n Enable Purge Mode (y/N): "
		read -r purgemode
		if [ "$purgemode" == Y ] || [ "$purgemode" == y ]; then
			purgemode=true
		else
			purgemode=false
		fi
		jq '.configurations.purge = "'"${purgemode}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
		unset purgemode
	else
		kill $$
	fi
	unset firstrun
	if [ "${instalationtype}" == 1 ]; then
		printf "\n [ START ] Software Instalation List\n"
		starttime=$(date +%s)
		i=0
		for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
			_jq() {
				echo "${row}" | base64 --decode | jq -r "${1}"
			}
			printf "\n Use default program instalation (y/N): "
			read -r defaultprogram
			if [ "$defaultprogram" == Y ] || [ "$defaultprogram" == y ]; then
				programdefault=$(_jq '.default')
				jq '.programs['"${i}"'].installation = "'"${programdefault}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
			fi
			((i++))
			if [ "$(_jq '.installation')" == true ]; then
				echo " $(_jq '.name'): $(_jq '.installation')"
			fi
		done
		sleep 3
		endtime=$(date +%s)
		printf " [ DONE ] Software Instalation List ... %s seconds\n" "$((endtime - starttime))"
	elif [ "${instalationtype}" == 2 ]; then
		printf "\n Your Name (Default: Matheus Rocha Vieira): "
		read -r username
		if [ -z "${username}" ]; then
			username="Matheus Rocha Vieira"
			echo "$username"
		fi
		jq '.personal.name = "'"${username}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
		unset username
		printf "\n Your E-Mail (Default: matheusrv@email.com): "
		read -r email
		if [ -z "${email}" ]; then
			email="matheusrv@email.com"
			echo "$email"
		fi
		jq '.personal.email = "'"${email}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
		unset email
		printf "\n Your GitHub Username (Default: MatheusRV): "
		read -r githubuser
		if [ -z "${githubuser}" ]; then
			githubuser="MatheusRV"
			echo "$githubuser"
		fi
		jq '.personal.githubuser = "'"${githubuser}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
		unset githubuser
		if [[ ! "$(uname -r)" =~ "Microsoft$" ]]; then
			defaultoption="(Default for WSL: '/mnt/c/Dev')"
		else
			defaultoption="(Default for Unix-like: '~/Dev')"
		fi
		printf "\n Default Dev Folder %s: " "$defaultoption"
		read -r defaultfolder
		if [ -z "${defaultfolder}" ]; then
			if [[ ! "$(uname -r)" =~ "Microsoft$" ]]; then
				defaultfolder=/mnt/c/Dev
			else
				defaultfolder=~/Dev
			fi
			if [ ! -d "${defaultfolder}" ]; then
				mkdir "${defaultfolder}"
			fi
			echo "${defaultfolder}"
		else
			if [ ! -d "${defaultfolder}" ]; then
				mkdir ${defaultfolder}
				echo "${defaultfolder}"
			fi
		fi
		jq '.personal.defaultfolder = "'"${defaultfolder}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
		unset defaultfolder
		i=0
		for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
			_jq() {
				echo "${row}" | base64 --decode | jq -r "${1}"
			}
			programdefault=$(_jq '.default')
			if [ "$programdefault" == true ]; then
				defaultoption="(Y/n)"
			else
				defaultoption="(y/N)"
			fi
			printf "\n Install %s %s: " "$(_jq '.name')" "$defaultoption"
			read -r programname
			if [ "$programname" == Y ] || [ "$programname" == y ]; then
				programinstallation=true
			elif [ -z "$programname" ]; then
				programinstallation="${programdefault}"
				echo "${programdefault}"
			else
				programinstallation=false
			fi
			jq '.programs['"${i}"'].installation = "'"${programinstallation}"'"' "${PREVIOUS_PWD}"/bootstrap/settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/settings.json
			((i++))
		done
		unset programinstallation
		unset programdefault
		unset programname
		unset defaultoption
		unset i
	else
		kill $$
	fi
	unset instalationtype
	printf "\n [ START ] Version Control\n"
	starttime=$(date +%s)
	if [ -f "${PREVIOUS_PWD}"/bootstrap/version.json ]; then
		sudo rm -f version.json
	fi
	if ! curl https://raw.githubusercontent.com/MatheusRV/dotfiles/master/bootstrap/version.json --create-dirs -o "${PREVIOUS_PWD}"/bootstrap/version.json; then
		echo "Download failed downloading version control! Exiting."
		kill $$
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Version Control ... %s seconds\n" "$((endtime - starttime))"
	for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/settings.json); do
		_jq() {
			echo "${row}" | base64 --decode | jq -r "${1}"
		}
		if [ "$(_jq '.installation')" == true ]; then
			programslug="$(_jq '.program')"
			#shellcheck disable=SC2116
			programname="$(echo _jq '.name')"
			programdependencies="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").dependencies' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			dependencieinstallation="$(jq -r '.programs[] | select(.program=="'"${programdependencies}"'").installation' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			if [ "${programdependencies}" == "null" ] || [ "${dependencieinstallation}" == true ]; then
				installflag=true
			else
				installflag=false
				printf "\n [ ERROR ] You are instaling %s without install it dependecies\n" "$($programname)"
			fi
			if [ "${installflag}" == true ]; then
				printf "\n [ START ] %s\n" "$($programname)"
				starttime=$(date +%s)
				#if [ ! -f "${PREVIOUS_PWD}"/programs/"${programslug}".sh ]; then
				#	if ! curl programs/"${programslug}".sh -L https://raw.githubusercontent.com/MatheusRV/dotfiles/master/programs/"${programslug}".sh --create-dirs -o "${PREVIOUS_PWD}"//,sh ; then
				#		echo "${programslug} download failed! Exiting."
				#	fi
				#i
				"${PREVIOUS_PWD}"/programs/"${programslug}".sh || installationerror=true
				wait
				if [ "${installationerror}" == true ]; then
					installationerror=false
					endtime=$(date +%s)
					printf " [ ERROR ] %s returns a non-zero exit status ... %s seconds\n" "$($programname)" "$((endtime - starttime))"
				else
					programconfiguration="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").config' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
					if [ "${programconfiguration}" == true ]; then
						printf "\n [ START ] %s configuration\n" "$($programname)"
						"${PREVIOUS_PWD}"/programs/"${programslug}"-config.sh || installationerror=true
						wait
						if [ "${installationerror}" == true ]; then
							installationerror=false
							printf " [ ERROR ] %s configuration returns a non-zero exit status\n" "$($programname)"
						else
							printf " [ DONE ] %s configuration\n" "$($programname)"
						fi
					fi
					endtime=$(date +%s)
					printf " [ DONE ] %s ... %s seconds\n" "$($programname)" "$((endtime - starttime))"
				fi
			fi
		fi
	done
	unset installflag
	unset installationerror
	unset programname
	unset programdependencies
	unset dependencieinstallation
	printf "\n [ START ] Common Requirements\n"
	starttime=$(date +%s)
	apps=(
		htop
		tmux
		shellcheck
	)
	sudo apt -y install "${apps[@]}"
	unset apps
	endtime=$(date +%s)
	printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime - starttime))"
	printf "\n [ START ] Cleaning\n"
	starttime=$(date +%s)
	sudo apt -y autoremove && sudo apt -y autoclean && sudo apt -y clean
	cd "${PREVIOUS_PWD}" && echo "cd ${PREVIOUS_PWD}" || return
	sudo rm -R -f "${HOME}"/tmp
	endtime=$(date +%s)
	printf " [ DONE ] Cleaning ... %s seconds\n" "$((endtime - starttime))"
	endtotaltime=$(date +%s)
	printf "\n Total Execution Time ... %s seconds\n" "$((endtotaltime - starttotaltime))"
} # this ensures the entire script is downloaded #
