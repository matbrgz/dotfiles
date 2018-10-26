#!/bin/bash -e
{ # this ensures the entire script is downloaded #
clear
if [[ ! "$(uname -r)" =~ "Microsoft$" ]] ; then
  starttotaltime=$(date +%s)
  printf "\n Welcome to Windows Subsystem Linux Bootstrap Script  \n"
  echo " ( PRESS KEY '1' FOR EXPRESS INSTALL )"
  echo " ( PRESS KEY '2' FOR CUSTOM INSTALL )"
  echo " ( PRESS KEY '3' FOR SOFTWARE INSTALL )"
  printf "\nOption: "
  read -r instalationtype
  printf "\n [ START ] Fix Possible Erros \n"
  starttime=$(date +%s)
  sudo apt --fix-broken install
  sudo dpkg --configure -a
  endtime=$(date +%s)
  printf " [ DONE ] Fix Possible Erros ... %s seconds \n" "$((endtime-starttime))"
  printf "\n [ START ] Update & Upgrade \n"
  starttime=$(date +%s)
  sudo apt -y update && sudo apt -y upgrade && sudo apt -y dist-upgrade
  endtime=$(date +%s)
  printf " [ DONE ] Update & Upgrade ... %s seconds \n" "$((endtime-starttime))"
  printf " [ START ] Common Requirements \n"
  starttime=$(date +%s)
  sudo apt -y install software-properties-common build-essential apt-transport-https curl jq htop unzip shellcheck libssl-dev ca-certificates
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
  if [ "${instalationtype}" == 1 ] ; then
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
      #echo " php Composer: $(jq -r '.phpcomposer' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " Laravel: $(jq -r '.laravel' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " MySQL: $(jq -r '.mysql' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " MySQL Password: $(jq -r '.mysqlpassword' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " phpMyAdmin: $(jq -r '.phpmyadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " Postgre: $(jq -r '.postgre' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " PostGIS: $(jq -r '.postgis' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " pgAdmin: $(jq -r '.pgadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " Redis: $(jq -r '.redis' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
      echo " Node Version Management : $(jq -r '.nvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
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
    elif [ "${instalationtype}" == 2 ] ; then
      sudo rm -f "${PREVIOUS_PWD}"/bootstrap/settings.json
      printf "\n Default Dev Folder (Default for WSL: '/mnt/c/Dev'): "
      read -r defaultfolder
      if [ -z "${defaultfolder}" ] ; then
          #mkdir /mnt/c/Dev
          defaultfolder=/mnt/c/Dev
          printf "/mnt/c/Dev"
      fi
      printf "\n  Install SSH (Y/n): "
      read -r ssh
      if [ -z "${ssh}" ] ; then
          ssh=y
          printf "Yes"
      elif [ "${ssh}" == Y ]; then
          ssh=y
      fi
      printf "\n  Install Protobuf (y/N): "
      read -r protobuf
      if [ -z "${protobuf}" ] ; then
          protobuf=n
          printf "No"
      elif [ "${protobuf}" == Y ]; then
          protobuf=y
      fi
      printf "\n Install Azure CLI (y/N): "
      read -r azurecli
      if [ -z "${azurecli}" ] ; then
          azurecli=n
          printf "No"
      elif [ "${azurecli}" == Y ]; then
          azurecli=y
      fi
      printf "\n Install Heroku CLI (y/N): "
      read -r herokucli
      if [ -z "${herokucli}" ] ; then
          herokucli=n
          printf "No"
      elif [ "${herokucli}" == Y ]; then
          herokucli=y
      fi
      printf "\n Install GoogleCloud CLI (y/N): "
      read -r gcloudcli
      if [ -z "${gcloudcli}" ] ; then
          gcloudcli=n
          printf "No"
      elif [ "${gcloudcli}" == Y ]; then
          gcloudcli=y
      fi
      printf "\n Install Google SDK (y/N): "
      read -r gcloudsdk
      if [ -z "${gcloudsdk}" ] ; then
          gcloudsdk=n
          printf "No"
      elif [ "${gcloudsdk}" == Y ]; then
          gcloudsdk=y
      fi
      printf "\n Install R (rlang) (y/N): "
      read -r rlang
      if [ -z "${rlang}" ] ; then
          rlang=n
          printf "No"
      elif [ "${rlang}" == Y ]; then
          rlang=y
      fi
      printf "\n Install .NET (y/N): "
      read -r dotnet
      if [ -z "${dotnet}" ] ; then
          dotnet=n
          printf "No"
      fi
      if [ "${dotnet}" == Y ] || [ "${dotnet}" == y ] ; then
          dotnet=y
          printf "\n Install .NET NuGET (Y/n): "
          read -r dotnetnuget
          if [ -z "${dotnetnuget}" ] ; then
              dotnetnuget=y
              printf "Yes"
          elif [ "${dotnetnuget}" == Y ]; then
              dotnetnuget=y
          fi
          printf "\n Install .NET Mono (y/N): "
          read -r dotnetmono
          if [ -z "${dotnetmono}" ] ; then
              dotnetmono=n
              printf "No"
          elif [ "${dotnetmono}" == Y ]; then
              dotnetmono=y
          fi
      else
          dotnetnuget=n
          dotnetmono=n
      fi
      printf "\n Install Apache (Y/n): "
      read -r apache
      if [ -z "${apache}" ] ; then
          apache=y
          printf "Yes"
      elif [ "${apache}" == Y ]; then
          apache=y
      fi
      printf "\n Install Nginx (y/N): "
      read -r nginx
      if [ -z "${nginx}" ] ; then
          nginx=n
          printf "Yes"
      elif [ "${nginx}" == Y ]; then
          nginx=y
      fi
      printf "\n php Version: (Type 72 for php7.2, type 7.1 for php7.1 or 56 for php5.6 or 'n' to escape): "
      read -r phpv
      if [ -z "${phpv}" ] ; then
          phpv=72
          printf "php7.2"
      fi
      if [ ! "${phpv}" == N ] || [ ! "${phpv}" == n ] ; then
          printf "\n Install Laravel (Y/n): "
          read -r laravel
          if [ -z "${laravel}" ] ; then
              laravel=y
              printf "Yes"
          elif [ "${laravel}" == Y ]; then
              laravel=y
          fi
      else
          laravel=n
      fi
      printf "\n Install MySQL: (Y/n): "
      read -r mysql
      if [ -z "${mysql}" ] ; then
          mysql=y
          printf "Yes"
      fi
      if [ "$mysql" == Y ] || [ "$mysql" == y ] ; then
          mysql=y
          printf "\n MySQL root Password: (Default: 1234): "
          read -r mysqlpassword
          if [ -z "${mysqlpassword}" ] ; then
              mysqlpassword=1324
              printf "1234"
          fi
          printf "\n Install phpMyAdmin: (Y/n): "
          read -r phpmyadmin
          if [ -z "${phpmyadmin}" ] ; then
              phpmyadmin=y
              printf "Yes"
          elif [ "${phpmyadmin}" == Y ]; then
              phpmyadmin=y
          fi
      else
          phpmyadmin=n
      fi
      printf "\n Install Postgre: (y/N): "
      read -r postgre
      if [ -z "${postgre}" ] ; then
          postgre=n
          printf "No"
      fi
      if [ "$postgre" == Y ] || [ "$postgre" == y ] ; then
          postgre=y
          printf "\n PostGIS: (y/N): "
          read -r postgis
          if [ -z "${postgis}" ] ; then
              postgis=n
              printf "No"
          elif [ "${postgis}" == Y ]; then
              postgis=y
          fi
          printf "\n Install pgAdmin: (Y/n): "
          read -r pgadmin
          if [ -z "${pgadmin}" ] ; then
              pgadmin=y
              printf "Yes"
          elif [ "${pgadmin}" == Y ]; then
              pgadmin=y
          fi
      else
          postgis=n
          pgadmin=n
      fi
      printf "\n Install Redis: (y/N): "
      read -r redis
      if [ -z "${redis}" ] ; then
          redis=n
          printf "No"
      elif [ "${redis}" == Y ]; then
          redis=y
      fi
      printf "\n Install Node Version Manager: (Y/n): "
      read -r nvm
      if [ -z "${nvm}" ] ; then
          nvm=y
          printf "Yes"
      elif [ "${nvm}" == Y ]; then
          nvm=y
      fi
      printf "\n Install Anaconda: (y/N): "
      read -r anaconda
      if [ -z "${anaconda}" ] ; then
          anaconda=n
          printf "No"
      elif [ "${anaconda}" == Y ]; then
          anaconda=y
      fi
      printf "\n Re-install Python3: (Y/n): "
      read -r python3
      if [ -z "${python3}" ] ; then
          python3=y
          printf "Yes"
      elif [ "${python3}" == Y ]; then
          python3=y
      fi
      printf "\n Install Python3 Pip: (Y/n): "
      read -r pythonpip
      if [ -z "${pythonpip}" ] ; then
          pythonpip=y
          printf "Yes"
      elif [ "${pythonpip}" == Y ]; then
          pythonpip=y
      fi
      printf "\n Install pyenv: (y/N): "
      read -r pyenv
      if [ -z "${pyenv}" ] ; then
          pyenv=n
          printf "No"
      fi
      if [ "$pyenv" == Y ] || [ "$pyenv" == y ] ; then
          pyenv=y
          printf " Install pyenv-virtualenv: (Y/n): "
          read -r pyenvvirtualenv
          if [ -z "${pyenvvirtualenv}" ] ; then
              pyenvvirtualenv=y
              printf "Yes"
          elif [ "${pyenvvirtualenv}" == Y ]; then
              pyenvvirtualenv=y
          fi
      else
          pyenvvirtualenv=n
      fi
      printf " Install GoLang: (Y/n): "
      read -r golang
      if [ -z "${golang}" ] ; then
          golang=y
          printf "Yes"
      elif [ "${golang}" == Y ]; then
          golang=y
      fi
      printf " Install Ruby Version Manager: (Y/n): "
      read -r rvm
      if [ -z "${rvm}" ] ; then
          rvm=y
          printf "Yes"
      fi
      if [ "$rvm" == Y ] || [ "$rvm" == y ] ; then
          rvm=y
          printf " Install Jekyll: (Y/n): "
          read -r jekyll
          if [ -z "${jekyll}" ] ; then
              jekyll=y
              printf "Yes"
          elif [ "${jekyll}" == Y ]; then
              jekyll=y
          fi
      else
          jekyll=n
      fi
      printf " Install Vagrant: (Y/n): "
      read -r vagrant
      if [ -z "${vagrant}" ] ; then
          vagrant=y
          printf "Yes"
      elif [ "${vagrant}" == Y ]; then
          vagrant=y
      fi
      printf " Install Docker: (Y/n): "
      read -r docker
      if [ -z "${docker}" ] ; then
          docker=y
          printf "Yes"
      fi
      if [ "$docker" == Y ] || [ "$docker" == y ] ; then
          docker=y
          printf " Install Docker Compose: (Y/n): "
          read -r dockercompose
          if [ -z "${dockercompose}" ] ; then
              dockercompose=y
              printf "Yes"
          elif [ "${dockercompose}" == Y ]; then
              dockercompose=y
          fi
      else
          dockercompose=n
      fi
      printf " Install Kubectl: (y/N): "
      read -r kubectl
      if [ -z "${kubectl}" ] ; then
          kubectl=n
          printf "No"
      fi
      if [ "$kubectl" == Y ] || [ "$kubectl" == y ] ; then
          kubectl=y
          printf " Install Kubernetes Helm: (Y/n): "
          read -r kuberneteshelm
          if [ -z "${kuberneteshelm}" ] ; then
              kuberneteshelm=y
              printf "Yes"
          elif [ "${kuberneteshelm}" == Y ]; then
              kuberneteshelm=y
          fi
      else
          kuberneteshelm=n
      fi
      printf " Install Mosh: (Y/n): "
      read -r mosh
      if [ -z "${mosh}" ] ; then
          mosh=y
          printf "Yes"
      elif [ "${mosh}" == Y ]; then
          mosh=y
      fi
      printf " Install Netkit: (Y/n): "
      read -r netkit
      if [ -z "${netkit}" ] ; then
          netkit=n
          printf "No"
      elif [ "${netkit}" == Y ]; then
          netkit=y
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
                    --arg redis "${redis}" \
                    --arg nvm "${nvm}" \
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
                    '{defaultfolder: $defaultfolder,ssh: $ssh, protobuf: $protobuf, azurecli: $azurecli, herokucli: $herokucli, gcloudcli: $gcloudcli, gcloudsdk: $gcloudsdk, rlang: $rlang, dotnet: $dotnet, dotnetnuget: $dotnetnuget, dotnetmono: $dotnetmono, apache: $apache, nginx: $nginx, phpv: $phpv, laravel: $laravel, mysql: $mysql, mysqlpassword: $mysqlpassword, phpmyadmin: $phpmyadmin, postgre: $postgre, postgis: $postgis, pgadmin: $pgadmin, redis: $redis, nvm: $nvm, anaconda: $anaconda, python3: $python3, pythonpip: $pythonpip, pyenv: $pyenv, pyenvvirtualenv: $pyenvvirtualenv, golang: $golang, rvm: $rvm, jekyll: $jekyll, vagrant: $vagrant, docker: $docker, dockercompose: $dockercompose, kubectl: $kubectl, kuberneteshelm: $kuberneteshelm, mosh: $mosh, netkit: $netkit}' )
      echo "${JSON_STRING}" >> "${PREVIOUS_PWD}"/bootstrap/settings.json
  elif [ "${instalationtype}" == 3 ] ; then
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
