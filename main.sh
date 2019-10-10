#!/bin/bash
{
    starttotaltime=$(date +%s)
    clear && clear
	PREVIOUS_PWD="${PWD}"
	cat <<EOF
 Welcome to Windows Subsystem Linux or Ubuntu Bootstrap Script v0.9.0
 Initializating script, please waiting until program configure itself.
 This may take a few minutes and you will be prompted for the password
 to elevate the user's permission several times.
EOF
    printf "\n [ START ] Configuring System Run"
    starttime=$(date +%s)
	if [ -d "${HOME}"/tmp ]; then
		sudo rm -f -R "${HOME}"/tmp
	fi
	mkdir -p "${HOME}"/tmp
	cd "${HOME}"/tmp || return
    sudo apt -qq update
    endtime=$(date +%s)
    printf " [ DONE ] Configuring System Run ... %s seconds\n" "$((endtime - starttime))"
    printf "\n [ START ] Instaling Major Requirements"
    starttime=$(date +%s)
    trap '' 2
    sudo apt -y install jq moreutils
    trap 2
    if [ ! -n "$(command -v jq)" ] || [ ! -n "$(command -v sponge)" ]; then
        printf "\n [ ERROR ] Command jq or sponge (moreutils) was not instaled sucessful. Restart script."
        kill $$
    fi
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
    jq '.configurations.debug = "'"${debugmode}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
    unset debugmode
    if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
        set +e
    else
        set -e
    fi
    printf "\n First time runing script? (Y/n/s): "
    read -r firstrun
    if [ -z "${firstrun}" ] || [ "${firstrun}" == Y ] || [ "${firstrun}" == y ]; then
        printf "\n [ START ] Update & Upgrade"
        starttime=$(date +%s)
        trap '' 2
        sudo apt -y upgrade && sudo apt -y dist-upgrade
        trap 2
        endtime=$(date +%s)
        printf " [ DONE ] Update & Upgrade ... %s seconds\n" "$((endtime - starttime))"
        printf "\n [ START ] Instaling Common Requirements"
        starttime=$(date +%s)
        apps=(
            software-properties-common
            build-essential
            apt-transport-https
            git
            curl
            unzip
            libssl-dev
            ca-certificates
        )
        trap '' 2
        sudo apt -y install "${apps[@]}"
        trap 2
        unset apps
        endtime=$(date +%s)
        printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime - starttime))"
        printf "\n [ START ] Configurating Command Alias"
        starttime=$(date +%s)
        trap '' 2
        "${PREVIOUS_PWD}"/configurations/alias.sh "${PREVIOUS_PWD}"
        wait
        trap 2
        endtime=$(date +%s)
        printf " [ DONE ] Configurating Command Alias ... %s seconds\n" "$((endtime - starttime))"
    elif [ "${firstrun}" == N ] || [ "${firstrun}" == n ]; then
        printf "\n [ START ] Fix Possible Erros"
        starttime=$(date +%s)
        trap '' 2
        sudo apt --fix-broken install
        sudo dpkg --configure -a
        trap 2
        endtime=$(date +%s)
        printf " [ DONE ] Fix Possible Erros ... %s seconds\n" "$((endtime - starttime))"

        printf "\n Install Config (y/N): "
        read -r configinstall
        if [ "$configinstall" == Y ] || [ "$configinstall" == y ]; then
            for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json); do
                _jq() {
                    echo "${row}" | base64 --decode | jq -r "${1}"
                }
                programslug="$(_jq '.program')"             
                if [ "$(_jq '.installation')" == true ]; then
                    programdependencies="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").dependencies' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
                    dependencieinstallation="$(jq -r '.programs[] | select(.program=="'"${programdependencies}"'").installation' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
                    if [ "${programdependencies}" == "null" ] || [ "${dependencieinstallation}" == true ]; then
                        installflag=true
                    else
                        installflag=false
                        printf "\n [ ERROR ] You are trying to configure %s without install it dependecies\n" "$(${programname})"
                    fi                    
                fi
                programconfiguration="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").config' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
                if [ "${installflag}" == true ] && [ "${programconfiguration}" == true ]; then
                    #shellcheck disable=SC2116
                    programname="$(echo _jq '.name')"
                    printf "\n [ START ] %s configuration" "$(${programname})"
                    trap 2
                    "${PREVIOUS_PWD}"/programs/"${programslug}"-config.sh "${PREVIOUS_PWD}" || installationerror=true
                    wait
                    trap 2
                    if [ "${installationerror}" == true ]; then
                        installationerror=false
                        printf "\n [ ERROR ] %s configuration returns a non-zero exit status\n" "$(${programname})"
                    else
                        printf " [ DONE ] %s configuration\n" "$(${programname})"
                    fi
                fi
            done
        fi
        printf "\n Enable Purge Mode (y/N): "
        read -r purgemode
        if [ "$purgemode" == Y ] || [ "$purgemode" == y ]; then
            purgemode=true
        else
            purgemode=false
        fi
        jq '.configurations.purge = "'"${purgemode}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
        unset purgemode
    fi
    unset firstrun
    if [ "${instalationtype}" == 1 ]; then
        printf "\n [ START ] Software Instalation List"
        starttime=$(date +%s)
        printf "\n Use default program instalation (y/N): "
        read -r defaultprogram
        printf "\n"
        i=0
        for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json); do
            _jq() {
                echo "${row}" | base64 --decode | jq -r "${1}"
            }
            if [ "$defaultprogram" == Y ] || [ "$defaultprogram" == y ]; then
                programdefault=$(_jq '.default')
                jq '.programs['"${i}"'].installation = "'"${programdefault}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            fi
            ((i++))
        done
        for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json); do
            _jq() {
                echo "${row}" | base64 --decode | jq -r "${1}"
            }
            if [ "$(_jq '.installation')" == true ]; then
                echo " $(_jq '.name'): $(_jq '.installation')"
            fi
        done
        sleep 3
        endtime=$(date +%s)
        printf " [ DONE ] Software Instalation List ... %s seconds\n" "$((endtime - starttime))"
    elif [ "${instalationtype}" == 2 ]; then
        printf "\n Config personal things (Y/n): "
        read -r personalconfig
        if [ -z "${personalconfig}" ] || [ "${personalconfig}" == Y ] || [ "${personalconfig}" == y ]; then
        
            printf "\n Your Name (Default: Matheus Rocha Vieira): "
            read -r username
            if [ -z "${username}" ]; then
                username="Matheus Rocha Vieira"
                echo "$username"
            fi
            git config --global user.name "${username}"
            jq '.personal.name = "'"${username}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            unset username
            printf "\n Your E-Mail (Default: matheusrv@email.com): "
            read -r email
            if [ -z "${email}" ]; then
                email="matheusrv@email.com"
                echo "$email"
            fi
            git config --global user.email "${email}"
            if [ ! -d ~/.ssh ]; then
                ssh-keygen -t rsa -b 4096 -C "${email}"
            fi
            jq '.personal.email = "'"${email}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            unset email
            printf "\n Your GitHub Username (Default: MatheusRV): "
            read -r githubuser
            if [ -z "${githubuser}" ]; then
                githubuser="MatheusRV"
                echo "$githubuser"
            fi
            jq '.personal.githubuser = "'"${githubuser}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            unset githubuser
            if [[ "$(uname -r)" =~ "Microsoft$" ]]; then
                defaultoption="(Default for WSL: '/mnt/c/Dev')"
            else
                defaultoption="(Default for Unix-like: '~/Dev')"
            fi
            printf "\n Default Dev Folder %s: " "$defaultoption"
            read -r defaultfolder
            if [ -z "${defaultfolder}" ]; then
                if [[ "$(uname -r)" =~ "Microsoft$" ]]; then
                    defaultfolder=/mnt/c/Dev
                else
                    defaultfolder=~/Dev
                fi
                if [ ! -d "${defaultfolder}" ]; then
                    mkdir "${defaultfolder}"
                    echo " [ DOING ] mkdir ${defaultfolder}"
                fi
                echo "${defaultfolder}"
            else
                if [ ! -d "${defaultfolder}" ]; then
                    mkdir ${defaultfolder}
                    echo " [ DOING ] mkdir ${defaultfolder}"
                fi
            fi
            jq '.personal.defaultfolder = "'"${defaultfolder}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            unset defaultfolder
        fi
        i=0
        for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json); do
            _jq() {
                echo "${row}" | base64 --decode | jq -r "${1}"
            }
            programslug="$(_jq '.program')"
            programdependencies="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").dependencies' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
            dependencieinstallation="$(jq -r '.programs[] | select(.program=="'"${programdependencies}"'").installation' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
            if [ "${programdependencies}" == "null" ] || [ "${dependencieinstallation}" == true ]; then
                programdefault=$(_jq '.default')
                if [ "$programdefault" == true ]; then
                    defaultoption="(Y/n)"
                else
                    defaultoption="(y/N)"
                fi
                printf "\n Install %s %s: " "$(_jq '.name')" "$defaultoption"
                read -r programname
                if [ "${programname}" == Y ] || [ "${programname}" == y ]; then
                    programinstallation=true
                    echo "${programinstallation}"
                elif [ -z "${programname}" ]; then
                    programinstallation="${programdefault}"
                    echo "${programdefault}"
                else
                    programinstallation=false
                    echo "${programinstallation}"
                fi
                jq '.programs['"${i}"'].installation = "'"${programinstallation}"'"' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json | sponge "${PREVIOUS_PWD}"/bootstrap/unix-settings.json
            else
                printf "\n %s depends on %s\n" "$(_jq '.name')" "$programdependencies"
            fi
            ((i++))
            unset programname
        done
        variables=(
            programname
            programdefault
            programinstallation
            defaultoption
            i
        )
        unset "${variables[@]}"
    else
        kill $$
    fi
    unset instalationtype
    for row in $(jq -r '.programs[] | @base64' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json); do
        _jq() {
            echo "${row}" | base64 --decode | jq -r "${1}"
        }
        programslug="$(_jq '.program')"
        if [ "$(_jq '.installation')" == true ]; then
            programdependencies="$(jq -r '.programs[] | select(.program=="'"${programslug}"'").dependencies' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
            dependencieinstallation="$(jq -r '.programs[] | select(.program=="'"${programdependencies}"'").installation' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
            if [ "${programdependencies}" == "null" ] || [ "${dependencieinstallation}" == true ]; then
                installflag=true
            else
                installflag=false
                printf "\n [ ERROR ] You are instaling %s without install it dependecies\n" "$(${programname})"
            fi
        fi
        if [ "${installflag}" == true ]; then
            #shellcheck disable=SC2116
            programname="$(echo _jq '.name')"
            printf "\n [ START ] %s" "$(${programname})"
            starttime=$(date +%s)
            trap '' 2
            "${PREVIOUS_PWD}"/programs/"${programslug}".sh "${PREVIOUS_PWD}" || installationerror=true
            wait
            trap 2
            if [ "${installationerror}" == true ]; then
                installationerror=false
                endtime=$(date +%s)
                printf "\n  [ ERROR ] %s returns a non-zero exit status ... %s seconds\n" "$(${programname})" "$((endtime - starttime))"
            fi
            endtime=$(date +%s)
            printf " [ DONE ] %s ... %s seconds\n" "$(${programname})" "$((endtime - starttime))"
        fi
        unset installflag
    done
    variables=(
        installflag
        installationerror
        programname
        dependencieinstallation
    )
    unset "${variables[@]}"
    printf "\n [ START ] Common Requirements"
    starttime=$(date +%s)
    apps=(
        htop
        tmux
    )
    trap '' 2
    sudo apt -y install "${apps[@]}"
    trap 2
    endtime=$(date +%s)
    printf " [ DONE ] Common Requirements ... %s seconds\n" "$((endtime - starttime))"
    printf "\n [ START ] Cleaning"
    starttime=$(date +%s)
    trap '' 2
    sudo apt -y autoremove && sudo apt -y autoclean && sudo apt -y clean
    trap 2
    cd "${PREVIOUS_PWD}" && echo " [ DOING ] cd ${PREVIOUS_PWD}" || return
    sudo rm -R -f "${HOME}"/tmp
    variables=(
        PREVIOUS_PWD
        starttotaltime
        endtotaltime
        starttime
        endtime
        apps
    )
    unset "${variables[@]}"
    endtime=$(date +%s)
    printf " [ DONE ] Cleaning ... %s seconds\n" "$((endtime - starttime))"
    endtotaltime=$(date +%s)
    printf "\n Total Execution Time ... %s seconds\n" "$((endtotaltime - starttotaltime))"
}
