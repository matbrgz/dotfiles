#!/bin/bash -e
{ # this ensures the entire script is downloaded #
	clear
	if [[ ! "$(uname -r)" =~ "Microsoft$" ]]; then
		starttotaltime=$(date +%s)
		printf "\n Welcome to Windows Subsystem Linux Bootstrap Script  \n"
		echo " ( PRESS KEY '1' FOR EXPRESS INSTALL )"
		echo " ( PRESS KEY '2' FOR CUSTOM INSTALL )"
		echo " ( PRESS KEY '3' FOR SOFTWARE INSTALL )"
		printf "\nOption: "
		read -r instalationtype
		#printf "\n [ START ] Fix Possible Erros \n"
		#starttime=$(date +%s)
		#sudo apt --fix-broken install
		#sudo dpkg --configure -a
		#endtime=$(date +%s)
		#printf " [ DONE ] Fix Possible Erros ... %s seconds \n" "$((endtime-starttime))"
		printf "\n [ START ] Update & Upgrade \n"
		starttime=$(date +%s)
		sudo apt -y update && sudo apt -y upgrade && sudo apt -y dist-upgrade
		endtime=$(date +%s)
		printf " [ DONE ] Update & Upgrade ... %s seconds \n" "$((endtime-starttime))"
		printf " [ START ] Common Requirements \n"
		starttime=$(date +%s)
		apps=(
			software-properties-common
			build-essential
			apt-transport-https
			curl
			jq
			htop
			tmux
			unzip
			shellcheck
			libssl-dev
			ca-certificates
		)
		sudo apt -y install "${apps[@]}"
		endtime=$(date +%s)
		printf " [ DONE ] Common Requirements ... %s seconds \n" "$((endtime-starttime))"
		PREVIOUS_PWD="${PWD}"
		if [ -d "${HOME}"/tmp ]; then
			sudo rm -f -R "${HOME}"/tmp
		fi
		mkdir -p "${HOME}"/tmp
		cd "${HOME}"/tmp
		JSON_STRING=$( jq -n \
				--arg pwd "${PREVIOUS_PWD}" \
			'{pwd: $pwd}' )
		echo "${JSON_STRING}" >> "${HOME}"/tmp/pwd.json
		if [ "${instalationtype}" == 1 ]; then
			echo " Default Folder: $(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " SSH: $(jq -r '.ssh' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Protobuf: $(jq -r '.protobuf' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Azure CLI: $(jq -r '.azurecli' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Google Cloud CLI: $(jq -r '.gcloudcli' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Google SDK: $(jq -r '.gcloudsdk' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " R : $(jq -r '.rlang' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " dotNet: $(jq -r '.dotnet' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " dotNet Mono: $(jq -r '.dotnetmono' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " dotNet NuGET: $(jq -r '.dotnetnuget' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Apache: $(jq -r '.apache' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Nginx: $(jq -r '.nginx' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " php: $(jq -r '.phpv' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " php Composer: $(jq -r '.phpcomposer' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Laravel: $(jq -r '.laravel' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " MySQL: $(jq -r '.mysql' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " MySQL Password: $(jq -r '.mysqlpassword' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " phpMyAdmin: $(jq -r '.phpmyadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Postgre: $(jq -r '.postgre' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " PostGIS: $(jq -r '.postgis' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " pgAdmin: $(jq -r '.pgadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Mongo: $(jq -r '.mongo' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Redis: $(jq -r '.redis' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Node Version Management : $(jq -r '.nvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Strapi : $(jq -r '.strapi' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Anaconda: $(jq -r '.anaconda' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Python3: $(jq -r '.python3' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Python Pip: $(jq -r '.pythonpip' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " PyEnv: $(jq -r '.pyenv' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " PyEnv VirtualEnv: $(jq -r '.pyenvvirtualenv' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Go: $(jq -r '.golang' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Ruby Version Management: $(jq -r '.rvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Jekyll: $(jq -r '.jekyll' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Vagrant: $(jq -r '.vagrant' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Docker: $(jq -r '.docker' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Docker Compose: $(jq -r '.dockercompose' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Kube CTL: $(jq -r '.kubectl' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Kubernetes Helm: $(jq -r '.kuberneteshelm' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			echo " Mosh: $(jq -r '.dotnet' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
			sleep 3
		elif [ "${instalationtype}" == 2 ]; then
			sudo rm -f "${PREVIOUS_PWD}"/bootstrap/settings.json
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
			printf "\n  Install SSH (Y/n): "
			read -r ssh
			if [ -z "${ssh}" ] || [ "${ssh}" == Y ] || [ "${ssh}" == y ]; then
				ssh=y
			else
				ssh=n
			fi
			printf "\n  Install Protobuf (y/N): "
			read -r protobuf
			if [ "${protobuf}" == Y ] || [ "${protobuf}" == y ]; then
				protobuf=y
			else
				protobuf=n
			fi
			printf "\n Install Azure CLI (y/N): "
			read -r azurecli
			if [ "${azurecli}" == Y ] || [ "${azurecli}" == y ]; then
				azurecli=y
			else
				azurecli=n
			fi
			printf "\n Install Heroku CLI (y/N): "
			read -r herokucli
			if [ "${herokucli}" == Y ] || [ "${herokucli}" == y ]; then
				herokucli=y
			else
				herokucli=n
			fi
			printf "\n Install GoogleCloud CLI (y/N): "
			read -r gcloudcli
			if [ "${gcloudcli}" == Y ] || [ "${gcloudcli}" == y ]; then
				gcloudcli=y
			else
				gcloudcli=n
			fi
			printf "\n Install Google SDK (y/N): "
			read -r gcloudsdk
			if [ "${gcloudsdk}" == Y ] || [ "${gcloudsdk}" == y ]; then
				gcloudsdk=y
			else
				gcloudsdk=n
			fi
			printf "\n Install R (rlang) (y/N): "
			read -r rlang
			if [ "${rlang}" == Y ] || [ "${rlang}" == y ]; then
				rlang=y
			else
				rlang=n
			fi
			printf "\n Install .NET (y/N): "
			read -r dotnet
			if [ "${dotnet}" == Y ] || [ "${dotnet}" == y ]; then
				dotnet=y
			else
				dotnet=n
			fi
			if [ "${dotnet}" == y ]; then
				printf "\n Install .NET NuGET (Y/n): "
				read -r dotnetnuget
				if [ -z "${dotnetnuget}" ] || [ "${dotnetnuget}" == Y ] || [ "${dotnetnuget}" == y ]; then
					dotnetnuget=y
				else
					dotnetnuget=n
				fi
				printf "\n Install .NET Mono (y/N): "
				read -r dotnetmono
				if [ "${dotnetmono}" == Y ] || [ "${dotnetmono}" == y ]; then
					dotnetmono=y
				else
					dotnetmono=n
				fi
			else
				dotnetnuget=n
				dotnetmono=n
			fi
			printf "\n Install Apache (Y/n): "
			read -r apache
			if [ -z "${apache}" ] || [ "${apache}" == Y ] || [ "${apache}" == y ]; then
				apache=y
			else
				apache=n
			fi
			printf "\n Install Nginx (y/N): "
			read -r nginx
			if [ "${nginx}" == Y ] || [ "${nginx}" == y ]; then
				nginx=y
			else
				nginx=n
			fi
			printf "\n php Version: (Type 72 for php7.2, type 7.1 for php7.1 or 56 for php5.6 or 'n' to escape): "
			read -r phpv
			if [ -z "${phpv}" ]; then
				phpv=72
				printf "php7.2"
			elif [ "${phpv}" == 7.1 ] || [ "${phpv}" == 71 ]; then
				phpv=71
				printf "php7.1"
			elif [ "${phpv}" == 5.6 ] || [ "${phpv}" == 56 ]; then
				phpv=56
				printf "php7.1"
			else
				phpv=n
			fi
			if [ ! "${phpv}" == n ]; then
				printf "\n Install Laravel (Y/n): "
				read -r laravel
				if [ -z "${laravel}" ] || [ "${laravel}" == Y ] || [ "${laravel}" == y ]; then
					laravel=y
				else
					laravel=n
				fi
				printf "\n Install php Composer (Y/n): "
				read -r phpcomposer
				if [ -z "${phpcomposer}" ] || [ "${phpcomposer}" == Y ] || [ "${phpcomposer}" == y ]; then
					phpcomposer=y
				else
					phpcomposer=n
				fi
			else
				laravel=n
				phpcomposer=n
			fi
			printf "\n Install MySQL: (Y/n): "
			read -r mysql
			if [ -z "${mysql}" ] || [ "${mysql}" == Y ] || [ "${mysql}" == y ]; then
				mysql=y
			else
				mysql=n
			fi
			if [ "$mysql" == y ]; then
				printf "\n MySQL root Password: (Default: 1234): "
				read -r mysqlpassword
				if [ -z "${mysqlpassword}" ]; then
					mysqlpassword=1234
					printf "1234"
				fi
				printf "\n Install phpMyAdmin: (Y/n): "
				read -r phpmyadmin
				if [ -z "${phpmyadmin}" ] || [ "${phpmyadmin}" == Y ] || [ "${phpmyadmin}" == y ]; then
					phpmyadmin=y
				else
					phpmyadmin=n
				fi
			else
				phpmyadmin=n
			fi
			printf "\n Install Postgre: (y/N): "
			read -r postgre
			if [ "${postgre}" == Y ] || [ "${postgre}" == y ]; then
				postgre=y
			else
				postgre=n
			fi
			if [ "$postgre" == y ]; then
				printf "\n PostGIS: (y/N): "
				read -r postgis
				if [ "${postgis}" == Y ] || [ "${postgis}" == y ]; then
					postgis=y
				else
					postgis=n
				fi
				printf "\n Install pgAdmin: (Y/n): "
				read -r pgadmin
				if [ -z "${pgadmin}" ] || [ "${pgadmin}" == Y ] || [ "${pgadmin}" == y ]; then
					pgadmin=y
				else
					pgadmin=n
				fi
			else
				postgis=n
				pgadmin=n
			fi
			printf "\n Install MongoDB: (Y/n): "
			read -r mongo
			if [ -z "${mongo}" ] || [ "${mongo}" == Y ] || [ "${mongo}" == y ]; then
				mongo=y
			else
				mongo=n
			fi
			printf "\n Install Redis: (y/N): "
			read -r redis
			if [ "${redis}" == Y ] || [ "${redis}" == y ]; then
				redis=y
			else
				redis=n
			fi
			printf "\n Install Node Version Manager: (Y/n): "
			read -r nvm
			if [ -z "${nvm}" ] || [ "${nvm}" == Y ] || [ "${nvm}" == y ]; then
				nvm=y
			else
				nvm=n
			fi
			if [ "$nvm" == y ]; then
				printf "\n Install Strapi: (Y/n): "
				read -r strapi
				if [ -z "${strapi}" ] || [ "${strapi}" == Y ] || [ "${strapi}" == y ]; then
					strapi=y
				else
					strapi=n
				fi
			else
				nvm=n
			fi
			printf "\n Install Anaconda: (y/N): "
			read -r anaconda
			if [ "${anaconda}" == Y ] || [ "${anaconda}" == y ]; then
				anaconda=y
			else
				anaconda=n
			fi
			printf "\n Re-install Python3: (Y/n): "
			read -r python3
			if [ -z "${python3}" ] || [ "${python3}" == Y ] || [ "${python3}" == y ]; then
				python3=y
			else
				python3=n
			fi
			printf "\n Install Python3 Pip: (Y/n): "
			read -r pythonpip
			if [ -z "${pythonpip}" ] || [ "${pythonpip}" == Y ] || [ "${pythonpip}" == y ]; then
				pythonpip=y
			else
				pythonpip=n
			fi
			printf "\n Install pyenv: (y/N): "
			read -r pyenv
			if [ "${pyenv}" == Y ] || [ "${pyenv}" == y ]; then
				pyenv=y
			else
				pyenv=n
			fi
			if [ "$pyenv" == y ]; then
				printf "\n Install pyenv-virtualenv: (Y/n): "
				read -r pyenvvirtualenv
				if [ -z "${pyenvvirtualenv}" ] || [ "${pyenvvirtualenv}" == Y ] || [ "${pyenvvirtualenv}" == y ]; then
					pyenvvirtualenv=y
				else
					pyenvvirtualenv=n
				fi
			else
				pyenvvirtualenv=n
			fi
			printf "\n Install GoLang: (Y/n): "
			read -r golang
			if [ -z "${golang}" ] || [ "${golang}" == Y ] || [ "${golang}" == y ]; then
				golang=y
			else
				golang=n
			fi
			printf "\n Install Ruby Version Manager: (Y/n): "
			read -r rvm
			if [ -z "${rvm}" ] || [ "${rvm}" == Y ] || [ "${rvm}" == y ]; then
				rvm=y
			else
				rvm=n
			fi
			if [ "$rvm" == y ]; then
				printf "\n Install Jekyll: (Y/n): "
				read -r jekyll
				if [ -z "${jekyll}" ] || [ "${jekyll}" == Y ] || [ "${jekyll}" == y ]; then
					jekyll=y
				else
					jekyll=n
				fi
			else
				jekyll=n
			fi
			printf "\n Install Vagrant: (Y/n): "
			read -r vagrant
			if [ -z "${vagrant}" ] || [ "${vagrant}" == Y ] || [ "${vagrant}" == y ]; then
				vagrant=y
			else
				vagrant=n
			fi
			printf "\n Install Docker: (Y/n): "
			read -r docker
			if [ -z "${docker}" ] || [ "${docker}" == Y ] || [ "${docker}" == y ]; then
				docker=y
			else
				docker=n
			fi
			if [ "$docker" == y ]; then
				printf "\n Install Docker Compose: (Y/n): "
				read -r dockercompose
				if [ -z "${dockercompose}" ] || [ "${dockercompose}" == Y ] || [ "${dockercompose}" == y ]; then
					dockercompose=y
				else
					dockercompose=n
				fi
			else
				dockercompose=n
			fi
			printf "\n Install Kubectl: (y/N): "
			read -r kubectl
			if [ "${kubectl}" == Y ] || [ "${kubectl}" == y ]; then
				kubectl=y
			else
				kubectl=n
			fi
			if [ "$kubectl" == y ]; then
				printf "\n Install Kubernetes Helm: (Y/n): "
				read -r kuberneteshelm
				if [ -z "${kuberneteshelm}" ] || [ "${kuberneteshelm}" == Y ] || [ "${kuberneteshelm}" == y ]; then
					kuberneteshelm=y
				else
					kuberneteshelm=n
				fi
			else
				kuberneteshelm=n
			fi
			printf "\n Install Mosh: (Y/n): "
			read -r mosh
			if [ -z "${mosh}" ] || [ "${mosh}" == Y ] || [ "${mosh}" == y ]; then
				mosh=y
			else
				mosh=n
			fi
			printf "\n Install Netkit: (y/N): "
			read -r netkit
			if [ "${netkit}" == Y ] || [ "${netkit}" == y ]; then
				netkit=y
			else
				netkit=n
			fi
			JSON_STRING=$( jq -n \
					--arg defaultfolder "${defaultfolder}" \
					--arg ssh "${ssh}" \
					--arg protobuf "${protobuf}" \
					--arg azurecli "${azurecli}" \
					--arg herokucli "${herokucli}" \
					--arg gcloudcli "${gcloudcli}" \
					--arg gcloudsdk "${gcloudsdk}" \
					--arg rlang "${rlang}" \
					--arg dotnet "${dotnet}" \
					--arg dotnetnuget "${dotnetnuget}" \
					--arg dotnetmono "${dotnetmono}" \
					--arg apache "${apache}" \
					--arg nginx "${nginx}" \
					--arg phpv "${phpv}" \
					--arg laravel "${laravel}" \
					--arg mysql "${mysql}" \
					--arg mysqlpassword "${mysqlpassword}" \
					--arg phpmyadmin "${phpmyadmin}" \
					--arg postgre "${postgre}" \
					--arg postgis "${postgis}" \
					--arg pgadmin "${pgadmin}" \
					--arg mongo "${mongo}" \
					--arg redis "${redis}" \
					--arg nvm "${nvm}" \
					--arg strapi "${strapi}" \
					--arg anaconda "${anaconda}" \
					--arg python3 "${python3}" \
					--arg pythonpip "${pythonpip}" \
					--arg pyenv "${pyenv}" \
					--arg pyenvvirtualenv "${pyenvvirtualenv}" \
					--arg golang "${golang}" \
					--arg rvm "${rvm}" \
					--arg jekyll "${jekyll}" \
					--arg vagrant "${vagrant}" \
					--arg docker "${docker}" \
					--arg dockercompose "${dockercompose}" \
					--arg kubectl "${kubectl}" \
					--arg kuberneteshelm "${kuberneteshelm}" \
					--arg mosh "${mosh}" \
					--arg netkit "${netkit}" \
				'{defaultfolder: $defaultfolder,ssh: $ssh, protobuf: $protobuf, azurecli: $azurecli, herokucli: $herokucli, gcloudcli: $gcloudcli, gcloudsdk: $gcloudsdk, rlang: $rlang, dotnet: $dotnet, dotnetnuget: $dotnetnuget, dotnetmono: $dotnetmono, apache: $apache, nginx: $nginx, phpv: $phpv, laravel: $laravel, mysql: $mysql, mysqlpassword: $mysqlpassword, phpmyadmin: $phpmyadmin, postgre: $postgre, postgis: $postgis, pgadmin: $pgadmin, mongo: $mongo, redis: $redis, nvm: $nvm, strapi: $strapi, anaconda: $anaconda, python3: $python3, pythonpip: $pythonpip, pyenv: $pyenv, pyenvvirtualenv: $pyenvvirtualenv, golang: $golang, rvm: $rvm, jekyll: $jekyll, vagrant: $vagrant, docker: $docker, dockercompose: $dockercompose, kubectl: $kubectl, kuberneteshelm: $kuberneteshelm, mosh: $mosh, netkit: $netkit}' )
			echo "${JSON_STRING}" >> "${PREVIOUS_PWD}"/bootstrap/settings.json
		elif [ "${instalationtype}" == 3 ]; then
			printf "\n Type software name: "
			read -r program
			export "${program,,}"=y
			sudo sed -i "/\"${program,,}\": \"n\"/c\"${program,,}\": \"y\"" "${PREVIOUS_PWD}"/bootstrap/settings.json
		fi
		"${PREVIOUS_PWD}"/bootstrap/main.sh
		wait
		printf " [ START ] Cleaning \n"
		starttime=$(date +%s)
		sudo apt -y autoremove && sudo apt -y autoclean && sudo apt -y clean
		endtime=$(date +%s)
		printf " [ DONE ] Cleaning ... %s seconds \n" "$((endtime-starttime))"
		cd "${PREVIOUS_PWD}"
		sudo rm -R -f "${HOME}"/tmp
		endtotaltime=$(date +%s)
		printf "Total Time ... %s seconds" "$((endtotaltime-starttotaltime))"
	else
		printf 'Not Implemented'
		exit 1
	fi
} # this ensures the entire script is downloaded #
