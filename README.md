# dotfiles
## Instaling WSL
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1604 -OutFile Ubuntu.appx -UseBasicParsing
or
curl.exe -L -o ubuntu-1604.appx https://aka.ms/wsl-ubuntu-1604
