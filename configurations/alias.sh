#!/bin/bash
PREVIOUS_PWD="$(jq -r '.pwd' "${HOME}"/tmp/pwd.json)"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/settings.json)" == true ] ; then
    set +e
else
    set -e
fi
defaultfolder="$(jq -r '.personal.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
echo "
# ls aliases
alias la=\"ls -al\"
alias ls=\"ls -h --color --group-directories-first\" # flat view w/ directories first
alias l=\"ls -h --color --group-directories-first\" # same as above
alias ll=\"ls -lv --group-directories-first\" # non-flat view
alias lm=\"ll | more\"

# Folder alias
alias hdir=\"cd ${HOME}\"
alias homedir=\"cd ${HOME}\"
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

if [[ ! "$(uname -r)" =~ "Microsoft$" ]] ; then
    echo '# Alias to run Windows cmd.exe from WSL
alias cmd="/mnt/c/Windows/System32/cmd.exe"
alias cmdc="/mnt/c/Windows/System32/cmd.exe /c"' >> "${HOME}"/.bash_aliases
fi