#!/bin/bash

# =============================================================================
# DOCKER COMPOSE INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install Docker Compose
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_docker_compose() {
	log_step "Installing Docker Compose"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Docker Compose installation"
		sudo rm -f /usr/local/bin/docker-compose
		sudo rm -f /usr/bin/docker-compose
	fi
	
	# Check if Docker Compose plugin is already available
	if docker compose version >/dev/null 2>&1; then
		log_info "Docker Compose plugin is already available"
		return 0
	fi
	
	# Try package manager first
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y docker-compose-plugin 2>/dev/null || install_docker_compose_standalone
			;;
		"pacman")
			sudo pacman -S --noconfirm docker-compose 2>/dev/null || install_docker_compose_standalone
			;;
		"yay")
			yay -S --noconfirm docker-compose 2>/dev/null || install_docker_compose_standalone
			;;
		"dnf")
			sudo dnf install -y docker-compose-plugin 2>/dev/null || install_docker_compose_standalone
			;;
		"zypper")
			sudo zypper install -y docker-compose 2>/dev/null || install_docker_compose_standalone
			;;
		"snap")
			sudo snap install docker 2>/dev/null || install_docker_compose_standalone
			;;
		"brew")
			brew install docker-compose 2>/dev/null || install_docker_compose_standalone
			;;
		*)
			install_docker_compose_standalone
			;;
	esac
	
	log_success "Docker Compose installed successfully"
}

install_docker_compose_standalone() {
	log_step "Installing Docker Compose standalone binary"
	
	local architecture
	local os_type
	local compose_version
	
	architecture=$(uname -m)
	os_type=$(uname -s)
	
	# Get latest version from GitHub API
	compose_version=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	
	if [[ -z "$compose_version" ]]; then
		log_warning "Could not determine latest Docker Compose version, using v2.20.0"
		compose_version="v2.20.0"
	fi
	
	log_info "Installing Docker Compose $compose_version"
	
	# Download and install
	local download_url="https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-${os_type}-${architecture}"
	
	if curl -L "$download_url" -o /tmp/docker-compose; then
		sudo mv /tmp/docker-compose /usr/local/bin/docker-compose
		sudo chmod +x /usr/local/bin/docker-compose
		
		# Create symlink for convenience
		sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true
		
		log_success "Docker Compose standalone binary installed"
	else
		log_error "Failed to download Docker Compose"
		return 1
	fi
}

setup_bash_completion() {
	log_step "Setting up bash completion for Docker Compose"
	
	local completion_dir="/etc/bash_completion.d"
	
	if [[ -d "$completion_dir" ]]; then
		# Docker Compose completion
		if [[ ! -f "$completion_dir/docker-compose" ]]; then
			sudo curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/bash/docker-compose -o "$completion_dir/docker-compose" 2>/dev/null || true
		fi
		
		log_success "Bash completion configured"
	else
		log_warning "Bash completion directory not found, skipping"
	fi
}

verify_installation() {
	log_step "Verifying Docker Compose installation"
	
	# Check Docker Compose plugin
	if docker compose version >/dev/null 2>&1; then
		local compose_version
		compose_version=$(docker compose version)
		log_success "Docker Compose plugin version: $compose_version"
		return 0
	fi
	
	# Check standalone Docker Compose
	if command -v docker-compose >/dev/null 2>&1; then
		local compose_version
		compose_version=$(docker-compose --version)
		log_success "Docker Compose standalone version: $compose_version"
		return 0
	fi
	
	log_error "Docker Compose installation verification failed"
	return 1
}

main() {
	log_info "Starting Docker Compose setup"
	
	# Check if Docker is installed
	if ! command -v docker >/dev/null 2>&1; then
		log_warning "Docker is not installed. Installing Docker first..."
		if [[ -f "$PROJECT_ROOT/programs/docker.sh" ]]; then
			"$PROJECT_ROOT/programs/docker.sh"
		else
			log_error "Docker installation script not found"
			return 1
		fi
	fi
	
	install_docker_compose
	setup_bash_completion
	verify_installation
	
	log_success "Docker Compose setup completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
