#!/bin/bash

# =============================================================================
# REDIS INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure Redis server
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_redis() {
	log_step "Installing Redis"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Redis installation"
		case "$pm" in
			"apt")
				sudo apt remove -y redis-server redis-tools 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm redis 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y redis 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install Redis
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y redis-server redis-tools
			;;
		"pacman")
			sudo pacman -S --noconfirm redis
			;;
		"yay")
			yay -S --noconfirm redis
			;;
		"dnf")
			sudo dnf install -y redis
			;;
		"zypper")
			sudo zypper install -y redis
			;;
		"snap")
			sudo snap install redis
			;;
		"brew")
			brew install redis
			;;
		*)
			log_error "Unsupported package manager: $pm"
			return 1
			;;
	esac
	
	log_success "Redis installed successfully"
}

configure_redis() {
	log_step "Configuring Redis"
	
	# Start and enable Redis service
	if command -v systemctl >/dev/null 2>&1; then
		sudo systemctl enable redis-server 2>/dev/null || sudo systemctl enable redis 2>/dev/null || true
		sudo systemctl start redis-server 2>/dev/null || sudo systemctl start redis 2>/dev/null || true
		log_success "Redis service started and enabled"
	else
		log_warning "systemctl not available, skipping service configuration"
	fi
}

verify_installation() {
	log_step "Verifying Redis installation"
	
	if command -v redis-cli >/dev/null 2>&1; then
		local version
		version=$(redis-cli --version)
		log_success "Redis CLI version: $version"
		
		# Test connection
		if redis-cli ping >/dev/null 2>&1; then
			log_success "Redis server is running and responding"
		else
			log_warning "Redis server is not responding to ping"
		fi
	else
		log_error "Redis CLI not found"
		return 1
	fi
}

main() {
	log_info "Starting Redis setup"
	
	install_redis
	configure_redis
	verify_installation
	
	log_success "Redis setup completed successfully"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
