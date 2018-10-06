#!/bin/bash -e
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
printf "\n [ START ] Version \n"
starttime=$(date +%s)
#"${PREVIOUS_PWD}"/bootstrap/version.sh
endtime=$(date +%s)
printf " [ DONE ] Version ... %s seconds \n" "$((endtime-starttime))"
defaultfolder="$(jq -r ".defaultfolder" "${PREVIOUS_PWD}"/bootstrap/settings.json)"
printf "\n [ START ] Alias \n"
starttime=$(date +%s)
echo "
# ls aliases
alias la=\"ls -al\"
alias ls=\"ls -h --color --group-directories-first\" # flat view w/ directories first
alias l=\"ls -h --color --group-directories-first\" # same as above
alias ll=\"ls -lv --group-directories-first\" # non-flat view
alias lm=\"ll | more\"

# Folder alias
alias hdir=\"cd ${HOME}\"
# shellcheck disable=SC2139
alias wdir=\"cd ${defaultfolder}\"

# Quick parent-directory aliases
alias ..=\"cd ..\"
alias ...=\"cd ../..\"
alias ....=\"cd ../../..\"
alias .....=\"cd ../../../..\"
alias ......=\"cd ../../../../..\"
alias .......=\"cd ../../../../../..\"
alias ........=\"cd ../../../../../../..\"
alias .........=\"cd ../../../../../../../..\"

# Others
alias editbash=\"nano ${HOME}/.bashrc\"
alias editba=\"nano ${HOME}/.bash_aliases\"
alias resource=\"source ${HOME}/.bashrc\"
" >> "${HOME}"/.bash_aliases
echo '
# Alias to run Windows cmd.exe from WSL
alias cmd="/mnt/c/Windows/System32/cmd.exe"
alias cmdc="/mnt/c/Windows/System32/cmd.exe /c"
' >> "${HOME}"/.bash_aliases
endtime=$(date +%s)
printf " [ DONE ] Alias ... %s seconds \n" "$((endtime-starttime))"
if [ "$(jq -r '.ssh' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/ssh.sh
    wait
fi
if [ "$(jq -r '.protobuf' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/protobuf.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.azurecli' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/azurecli.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.gcloudcli' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/gcloudcli.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.gcloudsdk' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/gcloudsdk.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.rlang' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/rlang.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.dotnet' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/dotnet.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.apache' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/apache.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.nginx' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/nginx.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.mysql' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/mysql.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.phpv' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == 72 ] ; then
    "${PREVIOUS_PWD}"/programs/php.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.postgre' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/postgre.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.redis' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/redis.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.nvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/nvm.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.anaconda' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/anaconda.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.python3' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/python3.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.golang' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/golang.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.rvm' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/rvm.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.vagrant' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/vagrant.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.docker' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/docker.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.kubectl' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/kubectl.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.mosh' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    "${PREVIOUS_PWD}"/programs/mosh.sh "${PREVIOUS_PWD}"
    wait
fi
if [ "$(jq -r '.netkit' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == y ] ; then
    echo "Disable until WSL not support ELF 32bits"
    "${PREVIOUS_PWD}"/programs/netkit.sh
    wait
fi
#"${PREVIOUS_PWD}"/configurations/bashrc.sh &
#"${PREVIOUS_PWD}"/configurations/personal.sh &
#wait
