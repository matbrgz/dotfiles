#!/bin/bash

# Vagrant Virtualization Platform Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="Vagrant Virtualization Platform"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_vagrant_version() {
	vagrant_version=$(get_json_value "vagrant")
	if [[ -z "$vagrant_version" || "$vagrant_version" == "null" ]]; then
		vagrant_version="2.4.2"
	fi
	echo "$vagrant_version"
}

# Check if Vagrant is already installed
check_vagrant_installation() {
	if command -v vagrant >/dev/null 2>&1; then
		log_warning "Vagrant is already installed"
		vagrant --version
		return 0
	fi
	return 1
}

# Install VirtualBox (virtualization provider)
install_virtualbox() {
	log_step "Installing VirtualBox"
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Add Oracle VirtualBox repository
			wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
			echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | \
				sudo tee /etc/apt/sources.list.d/virtualbox.list
			
			sudo apt-get update
			sudo apt-get install -y virtualbox-7.0 virtualbox-ext-pack
			;;
		yay|pacman)
			sudo pacman -S --needed --noconfirm virtualbox virtualbox-ext-oracle
			;;
		dnf)
			sudo dnf install -y VirtualBox
			;;
		zypper)
			sudo zypper install -y virtualbox
			;;
		brew)
			brew install --cask virtualbox
			;;
		*)
			log_warning "Package manager not supported for VirtualBox installation"
			log_warning "Please install VirtualBox manually from: https://www.virtualbox.org/"
			;;
	esac
	
	# Add user to vboxusers group (Linux only)
	if [[ "$(uname -s)" == "Linux" ]]; then
		sudo usermod -aG vboxusers "$USER"
		log_success "Added user to vboxusers group"
	fi
	
	log_success "VirtualBox installation completed"
}

# Install Vagrant
install_vagrant() {
	log_step "Installing Vagrant"
	
	local vagrant_version arch os_name
	vagrant_version=$(get_vagrant_version)
	
	# Detect architecture and OS
	case "$(uname -m)" in
		x86_64) arch="amd64" ;;
		aarch64|arm64) arch="arm64" ;;
		*) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
	esac
	
	case "$(uname -s)" in
		Linux) os_name="linux" ;;
		Darwin) os_name="darwin" ;;
		*) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
	esac
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Download and install Vagrant .deb package
			local deb_url="https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}-1_${arch}.deb"
			local temp_file="/tmp/vagrant_${vagrant_version}_${arch}.deb"
			
			log_step "Downloading Vagrant $vagrant_version"
			curl -fsSL "$deb_url" -o "$temp_file"
			
			log_step "Installing Vagrant package"
			sudo dpkg -i "$temp_file"
			sudo apt-get install -f -y  # Fix any dependency issues
			
			rm -f "$temp_file"
			;;
		yay|pacman)
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm vagrant
			else
				sudo pacman -S --noconfirm vagrant
			fi
			;;
		dnf)
			sudo dnf install -y vagrant
			;;
		zypper)
			sudo zypper install -y vagrant
			;;
		brew)
			brew install vagrant
			;;
		*)
			log_warning "Package manager not supported, attempting binary installation"
			install_vagrant_binary "$vagrant_version" "$arch" "$os_name"
			;;
	esac
	
	log_success "Vagrant installed successfully"
}

# Install Vagrant from binary (fallback method)
install_vagrant_binary() {
	local vagrant_version="$1"
	local arch="$2"
	local os_name="$3"
	
	log_step "Installing Vagrant from binary"
	
	# Download and install Vagrant
	local download_url="https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}_${os_name}_${arch}.zip"
	local temp_dir="/tmp/vagrant-install"
	
	mkdir -p "$temp_dir"
	cd "$temp_dir"
	
	log_step "Downloading Vagrant $vagrant_version"
	curl -fsSL "$download_url" -o "vagrant.zip"
	
	log_step "Extracting Vagrant"
	unzip -q "vagrant.zip"
	
	# Install to /usr/local/bin
	sudo cp vagrant /usr/local/bin/
	sudo chmod +x /usr/local/bin/vagrant
	
	# Cleanup
	cd /
	rm -rf "$temp_dir"
	
	log_success "Vagrant binary installation completed"
}

# Configure Vagrant
configure_vagrant() {
	log_step "Configuring Vagrant"
	
	# Create Vagrant home directory
	local vagrant_home="$HOME/.vagrant.d"
	mkdir -p "$vagrant_home"
	
	# Configure Vagrant settings
	export VAGRANT_HOME="$vagrant_home"
	
	# Configure for WSL if running on Windows Subsystem for Linux
	if [[ -n "${WSL_DISTRO_NAME:-}" ]] || [[ "$(uname -r)" =~ Microsoft$ ]]; then
		log_step "Configuring Vagrant for WSL"
		
		# WSL-specific configuration
		cat >> "$CONFIG_FILE" << 'EOF'

# Vagrant WSL Configuration
export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH="/mnt/c/Users/$USER"
export PATH="$PATH:/mnt/c/Program Files/Oracle/VirtualBox"
EOF
	fi
	
	# Add Vagrant environment variables
	if ! grep -q "VAGRANT_HOME" "$CONFIG_FILE" 2>/dev/null; then
		echo "export VAGRANT_HOME=\"$vagrant_home\"" >> "$CONFIG_FILE"
	fi
	
	log_success "Vagrant configuration completed"
}

# Install useful Vagrant plugins
install_vagrant_plugins() {
	log_step "Installing useful Vagrant plugins"
	
	# Essential plugins
	local plugins=(
		"vagrant-vbguest"       # VirtualBox Guest Additions management
		"vagrant-reload"        # Reload VM during provisioning
		"vagrant-hostmanager"   # Manage /etc/hosts file
		"vagrant-share"         # Share Vagrant environments
		"vagrant-disksize"      # Resize disk
	)
	
	for plugin in "${plugins[@]}"; do
		if ! vagrant plugin list | grep -q "$plugin"; then
			log_step "Installing plugin: $plugin"
			vagrant plugin install "$plugin" || log_warning "Failed to install $plugin"
		fi
	done
	
	log_success "Vagrant plugins installed"
}

# Create sample Vagrant environments
create_sample_environments() {
	log_step "Creating sample Vagrant environments"
	
	local vagrant_projects="$HOME/vagrant-projects"
	mkdir -p "$vagrant_projects"
	
	# Create Ubuntu development environment
	local ubuntu_env="$vagrant_projects/ubuntu-dev"
	if [[ ! -d "$ubuntu_env" ]]; then
		mkdir -p "$ubuntu_env"
		cd "$ubuntu_env"
		
		cat > Vagrantfile << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base box
  config.vm.box = "ubuntu/jammy64"
  
  # Network configuration
  config.vm.network "private_network", ip: "192.168.56.10"
  config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.network "forwarded_port", guest: 3000, host: 3000
  config.vm.network "forwarded_port", guest: 8000, host: 8000
  
  # VirtualBox provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "ubuntu-dev"
    vb.memory = "2048"
    vb.cpus = 2
    vb.gui = false
  end
  
  # Shared folder
  config.vm.synced_folder ".", "/vagrant", type: "virtualbox"
  config.vm.synced_folder "~/projects", "/home/vagrant/projects", create: true
  
  # Provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    apt-get update
    apt-get upgrade -y
    
    # Install development tools
    apt-get install -y curl wget git vim nano htop tree
    apt-get install -y build-essential software-properties-common
    
    # Install Node.js
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    apt-get install -y nodejs
    
    # Install Python
    apt-get install -y python3 python3-pip python3-venv
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker vagrant
    
    # Install Docker Compose
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    echo "Development environment setup completed!"
    echo "Access via: vagrant ssh"
    echo "Web services available on host:"
    echo "  - Port 8080 -> VM Port 80"
    echo "  - Port 3000 -> VM Port 3000" 
    echo "  - Port 8000 -> VM Port 8000"
  SHELL
end
EOF
		
		cat > README.md << 'EOF'
# Ubuntu Development Environment

A complete Ubuntu development environment with common development tools.

## Features

- Ubuntu 22.04 LTS
- Node.js (LTS version)
- Python 3 with pip and venv
- Docker and Docker Compose
- Git, Vim, development tools
- Port forwarding for web development

## Usage

```bash
# Start the environment
vagrant up

# SSH into the VM
vagrant ssh

# Stop the environment
vagrant halt

# Destroy the environment
vagrant destroy
```

## Network Configuration

- VM IP: 192.168.56.10
- Port 80 -> Host 8080
- Port 3000 -> Host 3000
- Port 8000 -> Host 8000

## Shared Folders

- Current directory -> /vagrant
- ~/projects -> /home/vagrant/projects
EOF
		
		log_success "Ubuntu development environment created at $ubuntu_env"
	fi
	
	# Create CentOS environment
	local centos_env="$vagrant_projects/centos-server"
	if [[ ! -d "$centos_env" ]]; then
		mkdir -p "$centos_env"
		cd "$centos_env"
		
		cat > Vagrantfile << 'EOF'
# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Base box
  config.vm.box = "generic/centos9s"
  
  # Network configuration
  config.vm.network "private_network", ip: "192.168.56.20"
  config.vm.network "forwarded_port", guest: 80, host: 8081
  
  # VirtualBox provider configuration
  config.vm.provider "virtualbox" do |vb|
    vb.name = "centos-server"
    vb.memory = "1024"
    vb.cpus = 1
  end
  
  # Provisioning script
  config.vm.provision "shell", inline: <<-SHELL
    # Update system
    dnf update -y
    
    # Install EPEL repository
    dnf install -y epel-release
    
    # Install common tools
    dnf install -y curl wget git vim nano htop tree
    dnf groupinstall -y "Development Tools"
    
    # Install nginx
    dnf install -y nginx
    systemctl enable nginx
    systemctl start nginx
    
    echo "CentOS server environment setup completed!"
    echo "Nginx is running on port 80"
  SHELL
end
EOF
		
		cat > README.md << 'EOF'
# CentOS Server Environment

A CentOS-based server environment for testing server applications.

## Features

- CentOS Stream 9
- Nginx web server
- Development tools
- Minimal server setup

## Usage

```bash
# Start the server
vagrant up

# SSH into the server
vagrant ssh

# Stop the server
vagrant halt
```

## Network Configuration

- VM IP: 192.168.56.20
- Port 80 -> Host 8081
EOF
		
		log_success "CentOS server environment created at $centos_env"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating Vagrant aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for Vagrant
	local vagrant_aliases="
# Vagrant Aliases
alias vup='vagrant up'
alias vhalt='vagrant halt'
alias vssh='vagrant ssh'
alias vstatus='vagrant status'
alias vreload='vagrant reload'
alias vdestroy='vagrant destroy'
alias vprovision='vagrant provision'
alias vpackage='vagrant package'
alias vbox-list='vagrant box list'
alias vbox-update='vagrant box update'
alias vbox-prune='vagrant box prune'
alias vglobal-status='vagrant global-status'
alias vdev='cd ~/vagrant-projects/ubuntu-dev && vagrant up && vagrant ssh'
alias vserver='cd ~/vagrant-projects/centos-server && vagrant up && vagrant ssh'
alias vprojects='cd ~/vagrant-projects'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "Vagrant Aliases" "$alias_file"; then
			echo "$vagrant_aliases" >> "$alias_file"
		fi
	else
		echo "$vagrant_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "Vagrant aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying Vagrant installation"
	
	if command -v vagrant >/dev/null 2>&1; then
		log_success "Vagrant installed successfully!"
		echo "  Version: $(vagrant --version)"
		echo "  Home directory: $VAGRANT_HOME"
		
		if command -v VBoxManage >/dev/null 2>&1; then
			echo "  VirtualBox: $(VBoxManage --version)"
		fi
		
		echo "  Installed plugins:"
		vagrant plugin list | sed 's/^/    /'
		
		return 0
	else
		log_error "Vagrant installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

Vagrant Virtualization Platform Usage:
=====================================

Basic Commands:
  vagrant up                  Start/create VM
  vagrant ssh                 SSH into VM
  vagrant halt                Stop VM
  vagrant destroy             Delete VM
  vagrant reload              Restart VM
  vagrant status              Show VM status

Box Management:
  vagrant box list            List downloaded boxes
  vagrant box add <name>      Download new box
  vagrant box update          Update boxes
  vagrant box prune           Remove old box versions

Environment Management:
  vagrant init <box>          Initialize new Vagrantfile
  vagrant provision           Run provisioning scripts
  vagrant package             Package VM as box

Useful Aliases:
  vup                         vagrant up
  vssh                        vagrant ssh
  vhalt                       vagrant halt
  vstatus                     vagrant status
  vdev                        Quick access to Ubuntu dev environment
  vserver                     Quick access to CentOS server
  vprojects                   Go to vagrant projects directory

Sample Environments:
  ~/vagrant-projects/ubuntu-dev/     Ubuntu development environment
  ~/vagrant-projects/centos-server/  CentOS server environment

Configuration Files:
  ~/.vagrant.d/               Vagrant home directory
  Vagrantfile                 VM configuration file

For more information: https://www.vagrantup.com/docs

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_vagrant_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install VirtualBox and Vagrant
	install_virtualbox
	install_vagrant
	configure_vagrant
	
	# Setup plugins and sample environments
	install_vagrant_plugins
	create_sample_environments
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "You may need to restart your shell or run: source ~/.bashrc"
		log_warning "On Linux, log out and back in to apply group changes"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
