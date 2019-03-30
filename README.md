# dotfiles
User-specific application configuration is traditionally stored in so called dotfiles. Dotfiles are plain text configuration files on Unix-y systems for things like our shell, ~/.zshrc, our editor in ~/.vimrc, and many others. They are called "dotfiles" as they typically are named with a leading . making them hidden files on your system, although this is not a strict requirement.

Since these files are all plain text, we can gather them together in a git repository and use that to track the changes you make over time.

## Install the Windows Subsystem for Linux
Before installing any Linux distros for WSL, you must ensure that the "Windows Subsystem for Linux" optional feature is enabled:

1. Open PowerShell as Administrator and run:
```Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux```
2. Restart your computer when prompted.
3. To download distros using PowerShell, use the Invoke-WebRequest cmdlet. Here's a sample instruction to download Ubuntu 18.04.
```Invoke-WebRequest -Uri https://aka.ms/wsl-ubuntu-1804 -OutFile Ubuntu.appx -UseBasicParsing```
or
```curl.exe -L -o ubuntu-1804.appx https://aka.ms/wsl-ubuntu-1804```
Note: Windows 10 Spring 2018 Update (or later) includes the popular curl command-line utility with which you can invoke web requests from the command line.

## TODO:
- [ ] APACHE: Make dynamic the choice of the port heard
- [ ] APACHE: Improve Configurations
- [ ] Generate SSL Certificates
- [ ] Unit Test
- [ ] Instalations test
- [ ] Create a default software choose order (MySQL than PHP)
- [ ] Output normalization

