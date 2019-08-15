#!/bin/bash
{
	clear && clear
	PREVIOUS_PWD="${PWD}"
	cat <<EOF
 Welcome to Windows Subsystem Linux Bootstrap Script
 Initializating script, please waiting until program configure itself.
 This may take a few minutes and you will be prompted for the password
 to elevate the user's permission.
EOF
	if [ -d "${HOME}"/tmp ]; then
		sudo rm -f -R "${HOME}"/tmp
	fi
	mkdir -p "${HOME}"/tmp
	cd "${HOME}"/tmp || return
	#TODO: Manage PowerShell install files dynamic
	: '
	printf "\n [ START ] Version Management Control\n"
	starttime=$(date +%s)
	trap '' 2
	if ! git clone https://github.com/molovo/lumberjack; then
		echo "Download failed downloading molovo/lumberjack! Exiting."
		kill $$
	fi
	if [ -d /usr/local/bin/lj ]; then
		filesha1=find "${PWD}"/lumberjack/lj -type f -print0 | xargs -0 sha1sum | sort | sha1sum
		filesha2=find /usr/local/bin/lj -type f -print0 | xargs -0 sha1sum | sort | sha1sum
		if [ "$filesha1" != "$filesha2" ]; then
			sudo rm -f -R /usr/local/bin/lj
			sudo mv lumberjack/lj /usr/local/bin
		fi
	else
		sudo mv lumberjack/lj /usr/local/bin
	fi
	if ! git clone https://github.com/MatheusRV/dotfiles; then
		echo "Download failed downloading matheusrv/dotfiles! Exiting."
		kill $$
	fi
	filesha1=find "${PWD}"/dotfiles -type f -print0 | xargs -0 sha1sum | awk '{print $1}' | sha1sum
	exit 1
	filesha2=find "${PREVIOUS_PWD}" -type f -print0 | xargs -0 sha1sum | sort | sha1sum
	if [ "$filesha1" != "$filesha2" ]; then
		if [ -d "${PREVIOUS_PWD}"/programs ]; then
			filesha1=find "${PWD}"/dotfiles/programs -type f -print0 | xargs -0 sha1sum | sort | sha1sum
			filesha2=find "${PREVIOUS_PWD}"/programs -type f -print0 | xargs -0 sha1sum | sort | sha1sum
			if [ "$filesha1" != "$filesha2" ]; then
				sudo rm -f -R "${PREVIOUS_PWD}"/programs
				sudo mv "${PWD}"/dotfiles/programs "${PREVIOUS_PWD}"/programs
			fi
		else
			sudo mv "${PWD}"/dotfiles/programs "${PREVIOUS_PWD}"/programs
		fi
		if [ -f "${PREVIOUS_PWD}"/main.sh ]; then
			filesha1=sha1sum "${PWD}"/dotfiles/main.sh
			filesha2=sha1sum "${PREVIOUS_PWD}"/main.sh
			if [ "$filesha1" != "$filesha2" ]; then
				sudo rm -f -R "${PREVIOUS_PWD}"/programs
				sudo mv "${PWD}"/dotfiles/programs "${PREVIOUS_PWD}"/programs
			fi
		else
			sudo mv "${PWD}"/dotfiles/main.sh "${PREVIOUS_PWD}"
		fi
	fi
	if [ -f "${PREVIOUS_PWD}"/bootstrap/version.json ]; then
		filesha1=sha1sum "${PWD}"/bootstrap/version.json
		filesha2=sha1sum "${PREVIOUS_PWD}"/bootstrap/version.json
		if [ "$filesha1" != "$filesha2" ]; then
			sudo rm -f "${PREVIOUS_PWD}"/bootstrap/version.json
			chmod +x "${PWD}"/bootstrap/version.json
			sudo mv "${PWD}"/bootstrap/version.json "${PREVIOUS_PWD}"/bootstrap
		fi
	else
		chmod +x "${PREVIOUS_PWD}"/bootstrap/version.json
		sudo mv "${PWD}"/bootstrap/version.json "${PREVIOUS_PWD}"/bootstrap
	fi
	if [ -f /usr/local/bin/chkinstall ]; then
		filesha1=sha1sum "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh
		filesha2=sha1sum /usr/local/bin/chkinstall
		if [ "$filesha1" != "$filesha2" ]; then
			sudo rm -f /usr/local/bin/chkinstall
			chmod +x "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh
			sudo cp "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh /usr/local/bin/chkinstall
		fi
	else
		chmod +x "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh
		sudo cp "${PREVIOUS_PWD}"/programs/tools-and-services/chkinstall.sh /usr/local/bin/chkinstall
	fi
	
	lj --file "${PREVIOUS_PWD}"/dotfiles.log --level debug
	trap 2
	endtime=$(date +%s)
	printf " [ DONE ] Version Control ... %s seconds\n" "$((endtime - starttime))"
	'
	"${PREVIOUS_PWD}"/main.sh "${PREVIOUS_PWD}"
}
