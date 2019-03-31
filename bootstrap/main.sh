#!/bin/bash -e
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
printf "\n [ START ] Version Control \n"
starttime=$(date +%s)
# Broken, needs investigation. Just exting!
#"${PREVIOUS_PWD}"/bootstrap/version.sh
endtime=$(date +%s)
printf " [ DONE ] Version Control ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.ssh' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] Secure Shell (SSH) \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/ssh.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " **************************** \n"
		printf " [ ERROR ] Secure Shell (SSH) \n"
		printf " **************************** \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Secure Shell (SSH) ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.protobuf' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] Google Protobuf \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/protobuf.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " ************************* \n"
		printf " [ ERROR ] Google Protobuf \n"
		printf " ************************* \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Google Protobuf ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.azurecli' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] Azure Comand-line Interface \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/azurecli.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " ************************************* \n"
		printf " [ ERROR ] Azure Comand-line Interface \n"
		printf " ************************************* \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Azure CLI ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.gcloudcli' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] Google Cloud Comand-line Interface \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/gcloudcli.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " ******************************************** \n"
		printf " [ ERROR ] Google Cloud Comand-line Interface \n"
		printf " ******************************************** \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Google Cloud Comand-line Interface ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.gcloudsdk' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] Google Cloud Software Development Kit \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/gcloudsdk.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " *********************************************** \n"
		printf " [ ERROR ] Google Cloud Software Development Kit \n"
		printf " *********************************************** \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] Google Cloud Software Development Kit ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.rlang' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	printf " [ START ] R Lang \n"
	starttime=$(date +%s)
	"${PREVIOUS_PWD}"/programs/rlang.sh || error=true
	wait
	if [ "${error}" == true ]; then
		printf " *********************************************** \n"
		printf " [ ERROR ] R Lang \n"
		printf " *********************************************** \n"
	fi
	endtime=$(date +%s)
	printf " [ DONE ] R Lang ... %s seconds \n" "$((endtime-starttime))"
fi
if [ "$(jq -r '.dotnet' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/dotnet.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.apache' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/apache.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.nginx' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/nginx.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.mysql' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/mysql.sh "${PREVIOUS_PWD}"
	wait
	if [ "$(jq -r '.phpmyadmin' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
		"${PREVIOUS_PWD}"/programs/mysql-phpmyadmin.sh
		wait
	fi
fi
if [ ! "$(jq -r '.phpv' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == n ] ; then
	"${PREVIOUS_PWD}"/programs/php.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.postgre' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/postgre.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.redis' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/redis.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.nvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/nvm.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.anaconda' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/anaconda.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.python3' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/python3.sh "${PREVIOUS_PWD}"
	wait
	if [ "$(jq -r '.pythonpip' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
		"${PREVIOUS_PWD}"/programs/python-pip.sh
		wait
	fi
	if [ "$(jq -r '.pyenv' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
		"${PREVIOUS_PWD}"/programs/pyenv.sh
		wait
	fi
fi
if [ "$(jq -r '.golang' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/golang.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.rvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/rvm.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.vagrant' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/vagrant.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.docker' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/docker.sh "${PREVIOUS_PWD}"
	wait
	if [ "$(jq -r '.dockercompose' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
		"${PREVIOUS_PWD}"/programs/docker-compose.sh
		wait
	fi
fi
if [ "$(jq -r '.kubectl' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/kubectl.sh "${PREVIOUS_PWD}"
	wait
	if [ "$(jq -r '.kuberneteshelm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
		"${PREVIOUS_PWD}"/programs/kubernetes-helm.sh
		wait
	fi
fi
if [ "$(jq -r '.mosh' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	"${PREVIOUS_PWD}"/programs/mosh.sh "${PREVIOUS_PWD}"
	wait
fi
if [ "$(jq -r '.netkit' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
	echo "Disable until WSL not support ELF 32bits"
	#"${PREVIOUS_PWD}"/programs/netkit.sh
	wait
fi