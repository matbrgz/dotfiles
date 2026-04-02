#!/bin/bash
PREVIOUS_PWD="$1"
if [ "$(jq -r '.configurations.debug' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)" == true ]; then
    set +e
else
    set -e
fi
defaultfolder="$(jq -r '.personal.defaultfolder' "${PREVIOUS_PWD}"/bootstrap/unix-settings.json)"
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
alias .4=\"cd ../../..\"
alias .5=\"cd ../../../..\"
alias .6=\"cd ../../../../..\"
alias .7=\"cd ../../../../../..\"
alias .8=\"cd ../../../../../../..\"
alias .9=\"cd ../../../../../../../..\"

# File and Folder Permission
alias mx=\"chmod a+x\"
alias 000=\"chmod 000\"
alias 644=\"chmod 644\"
alias 755=\"chmod 755\"
alias 777=\"chmod 777\"

# Others
alias editbash=\"nano ${HOME}/.bashrc\"
alias editba=\"nano ${HOME}/.bash_aliases\"
alias resource=\"source ${HOME}/.bashrc\"
alias hosts=\"nano /mnt/c/Windows/System32/drivers/etc/hosts\"
alias code=\"code .\"
alias np=\"cmd.exe /c notepad\"

#NetWork
alias ip=\"curl ipinfo.io/ip\"
alias ips=\"ifconfig -a | perl -nle'/(\d+.\d+.\d+.\d+)/ && print \$1'\"
alias speedtest=\"wget -O /dev/null http://speedtest.wdc01.softlayer.com/downloads/test100.zip\"

# Handy Extract Program
function extract()      
{
    if [ -f \$1 ] ; then
        case \$1 in
            *.tar.bz2)   tar xvjf \$1     ;;
            *.tar.gz)    tar xvzf \$1     ;;
            *.bz2)       bunzip2 \$1      ;;
            *.rar)       unrar x \$1      ;;
            *.gz)        gunzip \$1       ;;
            *.tar)       tar xvf \$1      ;;
            *.tbz2)      tar xvjf \$1     ;;
            *.tgz)       tar xvzf \$1     ;;
            *.zip)       unzip \$1        ;;
            *.Z)         uncompress \$1   ;;
            *.7z)        7z x \$1         ;;
            *)           echo \"'\$1' cannot be extracted via >extract<\" ;;
        esac
    else
        echo \"'\$1' is not a valid file!\"
    fi
}
 
 
# Make Dir and CD to it
function mcd ()
{
    mkdir -p \$1
    cd \$1
}
 
# Switch a File or Folder
function swap()
{
    if [ ! -z \"\$2\" ] && [ -e \"\$1\" ] && [ -e \"\$2\" ] && ! [ \"\$1\" -ef \"\$2\" ] && (([ -f \"\$1\" ] && [ -f \"\$2\" ]) || ([ -d \"\$1\" ] && [ -d \"\$2\" ])) ; then
        tmp=$(mktemp -d $(dirname \"\$1\")/XXXXXX)
        mv \"\$1\" \"\$tmp\" && mv \"\$2\" \"\$1\" &&  mv \"\$tmp\"/\"\$1\" \"\$2\"
        rmdir \"\$tmp\"
    else
        echo \"Usage: swap file1 file2 or swap dir1 dir2\"
    fi
}
 
# Creates an archive (*.tar.gz) from given directory.
function maketar() { tar cvzf \"\${1%%/}.tar.gz\"  \"\${1%%/}/\"; }
 
# Create a ZIP archive of a file or folder.
function makezip() { zip -r \"\${1%%/}.zip\" \"\$1\" ; }
 
# Make your directories and files access rights sane.
function sanitize() { chmod -R u=rwX,g=rX,o= \"\$@\" ;}

cd ${defaultfolder}
" >>"${HOME}"/.bash_aliases

if [[ ! "$(uname -r)" =~ "Microsoft$" ]]; then
    {
        # Alias to run Windows cmd.exe from WSL
        alias cmd="/mnt/c/Windows/System32/cmd.exe"
        alias cmdc="/mnt/c/Windows/System32/cmd.exe /c"
    } >>"${HOME}"/.bash_aliases
fi
