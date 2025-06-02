#!/bin/bash

# PowerShell Core Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="PowerShell Core"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_powershell_version() {
	powershell_version=$(get_json_value "powershell")
	if [[ -z "$powershell_version" || "$powershell_version" == "null" ]]; then
		powershell_version="7.4.6"
	fi
	echo "$powershell_version"
}

# Check if PowerShell is already installed
check_powershell_installation() {
	if command -v pwsh >/dev/null 2>&1; then
		log_warning "PowerShell is already installed"
		pwsh --version
		return 0
	fi
	return 1
}

# Install PowerShell Core
install_powershell() {
	log_step "Installing PowerShell Core"
	
	local powershell_version
	powershell_version=$(get_powershell_version)
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y wget apt-transport-https software-properties-common
			
			# Add Microsoft repository
			local ubuntu_version
			ubuntu_version=$(lsb_release -rs)
			wget -q "https://packages.microsoft.com/config/ubuntu/${ubuntu_version}/packages-microsoft-prod.deb"
			sudo dpkg -i packages-microsoft-prod.deb
			rm packages-microsoft-prod.deb
			
			# Update package list
			sudo apt-get update
			
			# Install PowerShell
			sudo apt-get install -y powershell
			;;
		yay|pacman)
			# Install from AUR or official repositories
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm powershell-bin
			else
				# Manual installation for Arch
				install_powershell_manual
			fi
			;;
		dnf)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo curl -o /etc/yum.repos.d/microsoft.repo https://packages.microsoft.com/config/rhel/8/prod.repo
			
			# Install PowerShell
			sudo dnf install -y powershell
			;;
		zypper)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo zypper addrepo https://packages.microsoft.com/rhel/7/prod/ microsoft
			sudo zypper refresh
			
			# Install PowerShell
			sudo zypper install -y powershell
			;;
		brew)
			# Install PowerShell via Homebrew
			brew install --cask powershell
			;;
		*)
			log_warning "Package manager not supported, attempting manual installation"
			install_powershell_manual
			;;
	esac
	
	log_success "PowerShell Core installed successfully"
}

# Install PowerShell manually (fallback method)
install_powershell_manual() {
	log_step "Installing PowerShell manually"
	
	local powershell_version arch os_name
	powershell_version=$(get_powershell_version)
	
	# Detect architecture and OS
	case "$(uname -m)" in
		x86_64) arch="x64" ;;
		aarch64|arm64) arch="arm64" ;;
		armv7l) arch="arm32" ;;
		*) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
	esac
	
	case "$(uname -s)" in
		Linux) os_name="linux" ;;
		Darwin) os_name="osx" ;;
		*) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
	esac
	
	# Download and install PowerShell
	local download_url="https://github.com/PowerShell/PowerShell/releases/download/v${powershell_version}/powershell-${powershell_version}-${os_name}-${arch}.tar.gz"
	local install_dir="/opt/microsoft/powershell/7"
	local temp_file="/tmp/powershell.tar.gz"
	
	log_step "Downloading PowerShell $powershell_version"
	curl -fsSL "$download_url" -o "$temp_file"
	
	# Create installation directory
	sudo mkdir -p "$install_dir"
	
	log_step "Extracting PowerShell"
	sudo tar -xzf "$temp_file" -C "$install_dir"
	
	# Create symbolic link
	sudo ln -sf "$install_dir/pwsh" /usr/local/bin/pwsh
	
	# Set executable permissions
	sudo chmod +x "$install_dir/pwsh"
	
	# Cleanup
	rm -f "$temp_file"
	
	log_success "PowerShell manual installation completed"
}

# Configure PowerShell
configure_powershell() {
	log_step "Configuring PowerShell"
	
	# Create PowerShell profile directory
	local profile_dir="$HOME/.config/powershell"
	mkdir -p "$profile_dir"
	
	# Create PowerShell profile
	local profile_file="$profile_dir/Microsoft.PowerShell_profile.ps1"
	if [[ ! -f "$profile_file" ]]; then
		cat > "$profile_file" << 'EOF'
# PowerShell Profile Configuration

# Set console encoding to UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Set PSReadLine options for better command line experience
if (Get-Module -ListAvailable -Name PSReadLine) {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function Complete
    Set-PSReadLineOption -ShowToolTips
}

# Custom prompt function
function prompt {
    $currentPath = (Get-Location).Path
    $homePattern = [regex]::Escape($HOME)
    $displayPath = $currentPath -replace "^$homePattern", "~"
    
    Write-Host "PS " -NoNewline -ForegroundColor Green
    Write-Host $displayPath -NoNewline -ForegroundColor Blue
    Write-Host " $" -NoNewline -ForegroundColor Green
    return " "
}

# Useful aliases
Set-Alias -Name ll -Value Get-ChildItem
Set-Alias -Name la -Value Get-ChildItem
Set-Alias -Name l -Value Get-ChildItem
Set-Alias -Name grep -Value Select-String
Set-Alias -Name which -Value Get-Command
Set-Alias -Name curl -Value Invoke-WebRequest
Set-Alias -Name wget -Value Invoke-WebRequest

# Custom functions
function Get-PublicIP {
    try {
        $response = Invoke-RestMethod -Uri "https://api.ipify.org?format=json"
        return $response.ip
    }
    catch {
        Write-Error "Failed to get public IP: $_"
    }
}

function Get-Weather {
    param([string]$City = "London")
    try {
        $response = Invoke-RestMethod -Uri "https://wttr.in/${City}?format=3"
        return $response
    }
    catch {
        Write-Error "Failed to get weather for ${City}: $_"
    }
}

function Get-SystemInfo {
    $os = Get-ComputerInfo | Select-Object WindowsProductName, WindowsVersion, TotalPhysicalMemory
    $cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
    
    Write-Host "System Information:" -ForegroundColor Green
    Write-Host "OS: $($os.WindowsProductName) $($os.WindowsVersion)" -ForegroundColor Yellow
    Write-Host "CPU: $($cpu.Name)" -ForegroundColor Yellow
    Write-Host "Cores: $($cpu.NumberOfCores) Physical, $($cpu.NumberOfLogicalProcessors) Logical" -ForegroundColor Yellow
    Write-Host "Memory: $([math]::Round($os.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor Yellow
}

function Test-Port {
    param(
        [string]$ComputerName,
        [int]$Port,
        [int]$TimeoutMs = 1000
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($TimeoutMs, $false)
        
        if ($wait) {
            $tcpClient.EndConnect($connect)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    }
    catch {
        return $false
    }
}

# Display welcome message
Write-Host "PowerShell Core Profile Loaded" -ForegroundColor Green
Write-Host "Available custom functions: Get-PublicIP, Get-Weather, Get-SystemInfo, Test-Port" -ForegroundColor Cyan
EOF
		
		log_success "PowerShell profile created at $profile_file"
	fi
	
	# Set PowerShell execution policy (if on Windows or with elevated permissions)
	if command -v pwsh >/dev/null 2>&1; then
		pwsh -c "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" 2>/dev/null || true
	fi
	
	log_success "PowerShell configured"
}

# Install useful PowerShell modules
install_powershell_modules() {
	log_step "Installing useful PowerShell modules"
	
	# Essential modules
	local modules=(
		"PSReadLine"          # Enhanced command line editing
		"PowerShellGet"       # Module management
		"PSScriptAnalyzer"    # Script analysis and linting
		"ImportExcel"         # Excel file manipulation
		"Az"                  # Azure PowerShell module
		"Microsoft.Graph"     # Microsoft Graph PowerShell SDK
		"SqlServer"           # SQL Server management
		"VMware.PowerCLI"     # VMware management
		"AWS.Tools.Common"    # AWS PowerShell tools
	)
	
	for module in "${modules[@]}"; do
		log_step "Installing module: $module"
		pwsh -c "Install-Module -Name '$module' -Force -Scope CurrentUser -AllowClobber" 2>/dev/null || log_warning "Failed to install $module"
	done
	
	log_success "PowerShell modules installed"
}

# Create sample PowerShell scripts
create_sample_scripts() {
	log_step "Creating sample PowerShell scripts"
	
	local scripts_dir="$HOME/powershell-scripts"
	mkdir -p "$scripts_dir"
	
	# Create system information script
	local sysinfo_script="$scripts_dir/Get-SystemInfo.ps1"
	if [[ ! -f "$sysinfo_script" ]]; then
		cat > "$sysinfo_script" << 'EOF'
#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Displays comprehensive system information
.DESCRIPTION
    Gathers and displays detailed system information including hardware, OS, and network details
.EXAMPLE
    .\Get-SystemInfo.ps1
#>

[CmdletBinding()]
param()

function Get-SystemInformation {
    Write-Host "System Information Report" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host ""
    
    # Operating System Information
    Write-Host "Operating System:" -ForegroundColor Yellow
    if ($IsWindows) {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem
        Write-Host "  Name: $($os.Caption)" -ForegroundColor White
        Write-Host "  Version: $($os.Version)" -ForegroundColor White
        Write-Host "  Architecture: $($os.OSArchitecture)" -ForegroundColor White
        Write-Host "  Install Date: $($os.InstallDate)" -ForegroundColor White
    } else {
        $os = uname -a
        Write-Host "  System: $os" -ForegroundColor White
    }
    Write-Host ""
    
    # Hardware Information
    Write-Host "Hardware Information:" -ForegroundColor Yellow
    if ($IsWindows) {
        $cpu = Get-CimInstance -ClassName Win32_Processor
        $memory = Get-CimInstance -ClassName Win32_ComputerSystem
        Write-Host "  Processor: $($cpu.Name)" -ForegroundColor White
        Write-Host "  Cores: $($cpu.NumberOfCores)" -ForegroundColor White
        Write-Host "  Logical Processors: $($cpu.NumberOfLogicalProcessors)" -ForegroundColor White
        Write-Host "  Total Memory: $([math]::Round($memory.TotalPhysicalMemory / 1GB, 2)) GB" -ForegroundColor White
    } else {
        $cpuInfo = Get-Content /proc/cpuinfo | Where-Object { $_ -match "model name" } | Select-Object -First 1
        $memInfo = Get-Content /proc/meminfo | Where-Object { $_ -match "MemTotal" }
        Write-Host "  Processor: $($cpuInfo -replace 'model name\s*:\s*', '')" -ForegroundColor White
        Write-Host "  Memory: $($memInfo -replace 'MemTotal:\s*', '')" -ForegroundColor White
    }
    Write-Host ""
    
    # PowerShell Information
    Write-Host "PowerShell Information:" -ForegroundColor Yellow
    Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor White
    Write-Host "  Platform: $($PSVersionTable.Platform)" -ForegroundColor White
    Write-Host ""
    
    # Network Information
    Write-Host "Network Information:" -ForegroundColor Yellow
    try {
        $publicIP = Invoke-RestMethod -Uri "https://api.ipify.org?format=json" -TimeoutSec 5
        Write-Host "  Public IP: $($publicIP.ip)" -ForegroundColor White
    } catch {
        Write-Host "  Public IP: Unable to retrieve" -ForegroundColor Red
    }
    
    if ($IsWindows) {
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $adapters) {
            $ip = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ip) {
                Write-Host "  $($adapter.Name): $($ip.IPAddress)" -ForegroundColor White
            }
        }
    } else {
        $interfaces = ip addr show | grep -E "inet " | grep -v "127.0.0.1"
        Write-Host "  Local IPs: $interfaces" -ForegroundColor White
    }
    Write-Host ""
    
    # Disk Information
    Write-Host "Disk Information:" -ForegroundColor Yellow
    if ($IsWindows) {
        $disks = Get-WmiObject -Class Win32_LogicalDisk
        foreach ($disk in $disks) {
            $freeGB = [math]::Round($disk.FreeSpace / 1GB, 2)
            $sizeGB = [math]::Round($disk.Size / 1GB, 2)
            $usedPercent = [math]::Round((($disk.Size - $disk.FreeSpace) / $disk.Size) * 100, 1)
            Write-Host "  Drive $($disk.DeviceID) $freeGB GB free of $sizeGB GB ($usedPercent% used)" -ForegroundColor White
        }
    } else {
        $diskInfo = df -h | grep -v "tmpfs"
        Write-Host "$diskInfo" -ForegroundColor White
    }
}

# Execute the function
Get-SystemInformation
EOF
		
		chmod +x "$sysinfo_script"
		log_success "System information script created at $sysinfo_script"
	fi
	
	# Create network testing script
	local network_script="$scripts_dir/Test-NetworkConnectivity.ps1"
	if [[ ! -f "$network_script" ]]; then
		cat > "$network_script" << 'EOF'
#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Tests network connectivity to various services
.DESCRIPTION
    Tests connectivity to common internet services and reports results
.EXAMPLE
    .\Test-NetworkConnectivity.ps1
#>

[CmdletBinding()]
param(
    [string[]]$Hosts = @("google.com", "github.com", "stackoverflow.com", "reddit.com", "youtube.com"),
    [int]$TimeoutSeconds = 5
)

function Test-NetworkConnectivity {
    param(
        [string[]]$TestHosts,
        [int]$Timeout
    )
    
    Write-Host "Network Connectivity Test" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
    Write-Host ""
    
    foreach ($host in $TestHosts) {
        Write-Host "Testing connection to $host..." -NoNewline
        
        try {
            if ($IsWindows) {
                $result = Test-NetConnection -ComputerName $host -Port 80 -WarningAction SilentlyContinue
                if ($result.TcpTestSucceeded) {
                    Write-Host " SUCCESS" -ForegroundColor Green
                    Write-Host "  Ping: $($result.PingSucceeded)" -ForegroundColor Yellow
                    Write-Host "  Port 80: $($result.TcpTestSucceeded)" -ForegroundColor Yellow
                } else {
                    Write-Host " FAILED" -ForegroundColor Red
                }
            } else {
                $ping = ping -c 1 -W $Timeout $host 2>/dev/null
                if ($LASTEXITCODE -eq 0) {
                    Write-Host " SUCCESS" -ForegroundColor Green
                    $time = $ping | grep -o "time=[0-9.]*ms" | head -1
                    Write-Host "  Response: $time" -ForegroundColor Yellow
                } else {
                    Write-Host " FAILED" -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host " ERROR: $_" -ForegroundColor Red
        }
        Write-Host ""
    }
    
    # Test DNS resolution
    Write-Host "DNS Resolution Test:" -ForegroundColor Green
    try {
        $dnsTest = Resolve-DnsName -Name "google.com" -Type A -ErrorAction Stop
        Write-Host "  DNS Resolution: SUCCESS" -ForegroundColor Green
        Write-Host "  Resolved IP: $($dnsTest.IPAddress)" -ForegroundColor Yellow
    }
    catch {
        Write-Host "  DNS Resolution: FAILED" -ForegroundColor Red
    }
    
    Write-Host ""
    
    # Test internet connectivity
    Write-Host "Internet Connectivity:" -ForegroundColor Green
    try {
        $response = Invoke-WebRequest -Uri "https://www.google.com" -UseBasicParsing -TimeoutSec $Timeout
        if ($response.StatusCode -eq 200) {
            Write-Host "  Internet Access: SUCCESS" -ForegroundColor Green
        } else {
            Write-Host "  Internet Access: PARTIAL (Status: $($response.StatusCode))" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "  Internet Access: FAILED" -ForegroundColor Red
    }
}

# Execute the test
Test-NetworkConnectivity -TestHosts $Hosts -Timeout $TimeoutSeconds
EOF
		
		chmod +x "$network_script"
		log_success "Network testing script created at $network_script"
	fi
	
	# Create README
	local readme="$scripts_dir/README.md"
	if [[ ! -f "$readme" ]]; then
		cat > "$readme" << 'EOF'
# PowerShell Scripts

Collection of useful PowerShell Core scripts for system administration and automation.

## Scripts

### Get-SystemInfo.ps1
Displays comprehensive system information including:
- Operating system details
- Hardware specifications
- PowerShell version information
- Network configuration
- Disk usage

Usage:
```powershell
pwsh ./Get-SystemInfo.ps1
```

### Test-NetworkConnectivity.ps1
Tests network connectivity to various services:
- Ping tests to specified hosts
- DNS resolution tests
- Internet connectivity verification

Usage:
```powershell
# Test default hosts
pwsh ./Test-NetworkConnectivity.ps1

# Test custom hosts
pwsh ./Test-NetworkConnectivity.ps1 -Hosts @("example.com", "github.com") -TimeoutSeconds 10
```

## PowerShell Profile

The PowerShell profile (`~/.config/powershell/Microsoft.PowerShell_profile.ps1`) includes:
- Enhanced command line experience with PSReadLine
- Custom prompt with current directory
- Useful aliases (ll, la, grep, which, etc.)
- Custom functions (Get-PublicIP, Get-Weather, Test-Port)

## Running Scripts

Execute PowerShell scripts using:
```bash
pwsh script-name.ps1
```

Or from within PowerShell:
```powershell
.\script-name.ps1
```

## Useful Commands

```powershell
# Get help for any cmdlet
Get-Help Get-Process -Full

# List all available modules
Get-Module -ListAvailable

# Install a module
Install-Module -Name ModuleName -Scope CurrentUser

# Get system information
Get-ComputerInfo

# Test network connectivity
Test-NetConnection -ComputerName google.com -Port 80

# Get running processes
Get-Process

# Get services
Get-Service

# Work with files and directories
Get-ChildItem
Set-Location /path/to/directory
Copy-Item source destination
```

## Resources

- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [PowerShell GitHub](https://github.com/PowerShell/PowerShell)
EOF
		
		log_success "README created at $readme"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating PowerShell aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for PowerShell
	local powershell_aliases="
# PowerShell Aliases
alias pwsh='pwsh'
alias ps='pwsh'
alias psh='pwsh'
alias powershell='pwsh'
alias psversion='pwsh -c \"\$PSVersionTable.PSVersion\"'
alias psprofile='pwsh -c \"\$PROFILE\"'
alias psmodules='pwsh -c \"Get-Module -ListAvailable\"'
alias pshelp='pwsh -c \"Get-Help\"'
alias psscripts='cd ~/powershell-scripts'
alias pssysinfo='pwsh ~/powershell-scripts/Get-SystemInfo.ps1'
alias psnettest='pwsh ~/powershell-scripts/Test-NetworkConnectivity.ps1'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "PowerShell Aliases" "$alias_file"; then
			echo "$powershell_aliases" >> "$alias_file"
		fi
	else
		echo "$powershell_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "PowerShell aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying PowerShell installation"
	
	if command -v pwsh >/dev/null 2>&1; then
		log_success "PowerShell Core installed successfully!"
		echo "  Version: $(pwsh -c '$PSVersionTable.PSVersion' 2>/dev/null || echo 'Unknown')"
		echo "  Edition: $(pwsh -c '$PSVersionTable.PSEdition' 2>/dev/null || echo 'Unknown')"
		echo "  Profile: ~/.config/powershell/Microsoft.PowerShell_profile.ps1"
		
		# Show installed modules count
		local module_count
		module_count=$(pwsh -c "(Get-Module -ListAvailable | Measure-Object).Count" 2>/dev/null || echo "0")
		echo "  Modules: $module_count available"
		
		return 0
	else
		log_error "PowerShell installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

PowerShell Core Usage:
=====================

Basic Commands:
  pwsh                        Start PowerShell
  pwsh -c "command"           Execute PowerShell command
  pwsh script.ps1             Run PowerShell script
  pwsh -Version               Show PowerShell version

PowerShell Cmdlets:
  Get-Help                    Get help for cmdlets
  Get-Command                 List available commands
  Get-Module                  List loaded modules
  Install-Module              Install PowerShell module
  Get-Process                 List running processes
  Get-Service                 List system services

File Operations:
  Get-ChildItem              List files and directories (ls equivalent)
  Set-Location               Change directory (cd equivalent)
  Copy-Item                  Copy files or directories
  Move-Item                  Move files or directories
  Remove-Item                Delete files or directories

Network Operations:
  Test-NetConnection         Test network connectivity
  Invoke-WebRequest          Make HTTP requests (curl equivalent)
  Resolve-DnsName            Resolve DNS names

Useful Aliases:
  pwsh                       PowerShell
  psversion                  Check PowerShell version
  psmodules                  List available modules
  psscripts                  Go to PowerShell scripts directory
  pssysinfo                  Run system information script
  psnettest                  Run network connectivity test

Sample Scripts:
  ~/powershell-scripts/Get-SystemInfo.ps1           System information
  ~/powershell-scripts/Test-NetworkConnectivity.ps1 Network testing

Configuration Files:
  ~/.config/powershell/Microsoft.PowerShell_profile.ps1  PowerShell profile

For more information: https://docs.microsoft.com/en-us/powershell/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_powershell_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure PowerShell
	install_powershell
	configure_powershell
	install_powershell_modules
	
	# Create sample scripts and aliases
	create_sample_scripts
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
