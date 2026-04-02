# https://github.com/microsoft/windows-dev-box-setup-scripts/blob/master/scripts/WSL.ps1

cinst -y Microsoft-Windows-Subsystem-Linux --source="'windowsfeatures'"

Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile ~/Ubuntu.appx -UseBasicParsing
Add-AppxPackage -Path ~/Ubuntu.appx

#curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
#Add-AppxPackage .\ubuntu-1804.appx
#Rename-Item ./ubuntu-1804.appx ./Ubuntu.zip
#Expand-Archive ./Ubuntu.zip C:\Users\Administrator\Ubuntu
#$userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
#[System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\Users\Administrator\Ubuntu", "User")

RefreshEnv

#if (!(Get-Command 'ubuntu1804' -ErrorAction SilentlyContinue)) {
#    Write-Error @'
#  You need Windows Subsystem for Linux setup before the rest of this script can run.
#  See https://docs.microsoft.com/en-us/windows/wsl/install-win10 for more information.
#'@
#    Exit
#}


Ubuntu1804 install --root
Ubuntu1804 run apt update
Ubuntu1804 run apt upgrade -y
#$ComputerName = (Get-Culture).TextInfo.ToLower("$ComputerName")

#if ((wsl awk '/^ID=/' /etc/*-release | wsl awk -F'=' '{ print tolower(\$2) }') -ne 'ubuntu1804') {
#    Write-Error 'Ensure Windows Subsystem for Linux is setup to run the Ubuntu distribution'
#    Exit
#}
  
#if ((wsl awk '/^DISTRIB_RELEASE=/' /etc/*-release | wsl awk -F'=' '{ print tolower(\$2) }') -lt 18.04) {
#    Write-Error 'You need to install a minimum of Ubuntu 18.04 Bionic Beaver before running this script'
#    Exit
#}

#Ubuntu1804 run "useradd $ComputerName --disabled-password; echo -e '1234\n1234' | passwd $ComputerName"
#Ubuntu1804 run usermod -aG sudo $ComputerName
#Ubuntu1804 run config --default-user $ComputerName

Ubuntu1804 run 'git clone https://github.com/MatheusRV/dotfiles && chmod 777 -R dotfiles && cd dotfiles && ./install.sh'

$Programs = @(
    "vcxsrv"
    "cmder"
)
        
ForEach ($Program in $Programs) {
    Write-Output "Instaling $Program"
    cinst -y $Program
}