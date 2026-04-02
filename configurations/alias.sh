#!/bin/bash -e
defaultfolder="$(jq -r '.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/settings.json)"
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