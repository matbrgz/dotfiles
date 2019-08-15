curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804
Add-AppxPackage .\ubuntu-1804.appx
Rename-Item ./ubuntu-1804.appx ./Ubuntu.zip
Expand-Archive ./Ubuntu.zip C:\Users\Administrator\Ubuntu
$userenv = [System.Environment]::GetEnvironmentVariable("Path", "User")
[System.Environment]::SetEnvironmentVariable("PATH", $userenv + ";C:\Users\Administrator\Ubuntu", "User")

refreshenv

if (!(Get-Command 'ubuntu1804' -ErrorAction SilentlyContinue)) {
    Write-Error @'
  You need Windows Subsystem for Linux setup before the rest of this script can run.
  See https://docs.microsoft.com/en-us/windows/wsl/install-win10 for more information.
'@
    Exit
}

$ComputerName = (Get-Culture).TextInfo.ToLower("$ComputerName")

Start-Process "ubuntu1804.exe" -ArgumentList "install --root" -Wait

if ((wsl awk '/^ID=/' /etc/*-release | wsl awk -F'=' '{ print tolower(\$2) }') -ne 'ubuntu1804') {
    Write-Error 'Ensure Windows Subsystem for Linux is setup to run the Ubuntu distribution'
    Exit
}
  
if ((wsl awk '/^DISTRIB_RELEASE=/' /etc/*-release | wsl awk -F'=' '{ print tolower(\$2) }') -lt 18.04) {
    Write-Error 'You need to install a minimum of Ubuntu 18.04 Bionic Beaver before running this script'
    Exit
}

Start-Process "ubuntu1804.exe" -ArgumentList "run useradd '$ComputerName' --disabled-password; echo -e '1234\n1234' | passwd '$ComputerName'" -Wait
Start-Process "ubuntu1804.exe" -ArgumentList "run usermod -aG sudo '$ComputerName'" -Wait
Start-Process "ubuntu1804.exe" -ArgumentList "config --default-user '$ComputerName'" -Wait

wsl bash -c "./install.sh"

$Programs = @(
    "vcxsrv"
    "cmder"
)
        
ForEach ($Program in $Programs) {
    Write-Output "Instaling $Program"
    cinst -y $Program
}