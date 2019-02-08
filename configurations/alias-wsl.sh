#!/bin/bash -e
echo '
# Alias to run Windows cmd.exe from WSL
alias cmd="/mnt/c/Windows/System32/cmd.exe"
alias cmdc="/mnt/c/Windows/System32/cmd.exe /c"
' >> "${HOME}"/.bash_aliases