#!/bin/bash

# =============================================================================
# DOCKER INSTALLATION AND CONFIGURATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure Docker with automatic distro detection
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_docker_apt() {
	log_step "Installing Docker via APT"
	
	# Remove old versions
	sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
	
	# Update packages
	sudo apt update
	
	# Install dependencies
	sudo apt install -y \
		apt-transport-https \
		ca-certificates \
		curl \
		gnupg \
		lsb-release
	
	# Add Docker's official GPG key
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
	
	# Set up the stable repository
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
	
	# Install Docker Engine
	sudo apt update
	sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
	
	log_success "Docker installed via APT"
}

install_docker_pacman() {
	log_step "Installing Docker via Pacman"
	
	sudo pacman -S --noconfirm docker docker-compose
	
	log_success "Docker installed via Pacman"
}

install_docker_yay() {
	log_step "Installing Docker via YAY"
	
	yay -S --noconfirm docker docker-compose
	
	log_success "Docker installed via YAY"
}

install_docker_dnf() {
	log_step "Installing Docker via DNF"
	
	# Remove old versions
	sudo dnf remove -y docker \
					  docker-client \
					  docker-client-latest \
					  docker-common \
					  docker-latest \
					  docker-latest-logrotate \
					  docker-logrotate \
					  docker-engine 2>/dev/null || true
	
	# Install dependencies
	sudo dnf install -y dnf-plugins-core
	
	# Add Docker repository
	sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
	
	# Install Docker
	sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
	
	log_success "Docker installed via DNF"
}

install_docker() {
	log_step "Installing Docker"
	
	local pm distro
	pm=$(detect_package_manager)
	distro=$(detect_distro)
	
	case "$pm" in
		"apt")
			install_docker_apt
			;;
		"pacman")
			install_docker_pacman
			;;
		"yay")
			install_docker_yay
			;;
		"dnf")
			install_docker_dnf
			;;
		"snap")
			sudo snap install docker
			;;
		*)
			log_error "Unsupported package manager: $pm"
			log_info "Please install Docker manually for your system"
			return 1
			;;
	esac
	
	# Start and enable Docker service
	sudo systemctl start docker
	sudo systemctl enable docker
	
	log_success "Docker installation completed"
}

configure_docker() {
	log_step "Configuring Docker"
	
	# Add user to docker group
	if ! groups "$USER" | grep -q docker; then
		sudo usermod -aG docker "$USER"
		log_success "Added $USER to docker group"
		log_warning "Please logout and login again for group changes to take effect"
	else
		log_info "User $USER is already in docker group"
	fi
	
	# Configure Docker daemon
	local docker_config_dir="/etc/docker"
	local daemon_config="$docker_config_dir/daemon.json"
	
	sudo mkdir -p "$docker_config_dir"
	
	# Create daemon configuration
	sudo tee "$daemon_config" > /dev/null << 'EOF'
{
	"log-driver": "json-file",
	"log-opts": {
		"max-size": "10m",
		"max-file": "3"
	},
	"storage-driver": "overlay2",
	"dns": ["8.8.8.8", "8.8.4.4"],
	"default-address-pools": [
		{
			"base": "172.80.0.0/12",
			"size": 24
		}
	]
}
EOF
	
	log_success "Docker daemon configured"
	
	# Restart Docker to apply configuration
	sudo systemctl restart docker
	
	log_success "Docker service restarted"
}

install_docker_compose() {
	log_step "Installing Docker Compose"
	
	# Check if Docker Compose is already installed via plugin
	if docker compose version >/dev/null 2>&1; then
		log_info "Docker Compose plugin is already installed"
		return 0
	fi
	
	# Install standalone Docker Compose if plugin is not available
	local compose_version
	compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	
	if [[ -z "$compose_version" ]]; then
		log_warning "Could not determine latest Docker Compose version, using v2.20.0"
		compose_version="v2.20.0"
	fi
	
	log_info "Installing Docker Compose $compose_version"
	
	sudo curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
	sudo chmod +x /usr/local/bin/docker-compose
	
	# Create symlink for convenience
	sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
	
	log_success "Docker Compose installed successfully"
}

setup_bash_completion() {
	log_step "Setting up bash completion"
	
	local completion_dir="/etc/bash_completion.d"
	
	if [[ -d "$completion_dir" ]]; then
		# Docker completion
		if [[ ! -f "$completion_dir/docker" ]]; then
			sudo curl -L https://raw.githubusercontent.com/docker/docker-ce/master/components/cli/contrib/completion/bash/docker -o "$completion_dir/docker"
		fi
		
		# Docker Compose completion
		if [[ ! -f "$completion_dir/docker-compose" ]]; then
			sudo curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o "$completion_dir/docker-compose"
		fi
		
		log_success "Bash completion configured"
	else
		log_warning "Bash completion directory not found, skipping"
	fi
}

verify_installation() {
	log_step "Verifying Docker installation"
	
	# Check Docker version
	if command -v docker >/dev/null 2>&1; then
		local docker_version
		docker_version=$(docker --version)
		log_success "Docker version: $docker_version"
	else
		log_error "Docker command not found"
		return 1
	fi
	
	# Check Docker Compose version
	if docker compose version >/dev/null 2>&1; then
		local compose_version
		compose_version=$(docker compose version)
		log_success "Docker Compose version: $compose_version"
	elif command -v docker-compose >/dev/null 2>&1; then
		local compose_version
		compose_version=$(docker-compose --version)
		log_success "Docker Compose version: $compose_version"
	else
		log_warning "Docker Compose not found"
	fi
	
	# Check Docker service status
	if systemctl is-active --quiet docker; then
		log_success "Docker service is running"
	else
		log_warning "Docker service is not running"
	fi
	
	log_success "Docker verification completed"
}

create_docker_alias() {
	log_step "Creating useful Docker aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Docker aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Docker aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Docker aliases
	cat >> "$bashrc" << 'EOF'

# Docker aliases added by matbrgz dotfiles
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dex='docker exec -it'
alias dlog='docker logs'
alias dlogf='docker logs -f'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'
alias drestart='docker restart'
alias dclean='docker system prune -f'
alias dcleanall='docker system prune -a -f'
alias dvol='docker volume ls'
alias dnet='docker network ls'
EOF
	
	log_success "Docker aliases added to $bashrc"
	log_info "Run 'source ~/.bashrc' or start a new shell to use the aliases"
}

main() {
	log_info "Starting Docker setup"
	
	# Check if Docker is already installed
	if command -v docker >/dev/null 2>&1; then
		log_info "Docker is already installed"
	else
		install_docker
	fi
	
	configure_docker
	install_docker_compose
	setup_bash_completion
	create_docker_alias
	verify_installation
	
	log_success "Docker setup completed successfully"
	
	# Show next steps
	echo
	log_info "Next steps:"
	echo "  1. Logout and login again to apply group changes"
	echo "  2. Test Docker with: docker run hello-world"
	echo "  3. Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
