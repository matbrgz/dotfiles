#!/bin/bash

# =============================================================================
# SSH SERVER INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure OpenSSH server
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_ssh() {
	log_step "Installing OpenSSH Server"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing SSH installation"
		case "$pm" in
			"apt")
				sudo apt remove -y openssh-server 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm openssh 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y openssh-server 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install SSH server
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y openssh-server
			;;
		"pacman")
			sudo pacman -S --noconfirm openssh
			;;
		"yay")
			yay -S --noconfirm openssh
			;;
		"dnf")
			sudo dnf install -y openssh-server
			;;
		"zypper")
			sudo zypper install -y openssh
			;;
		"brew")
			log_warning "SSH server not needed on macOS (built-in)"
			return 0
			;;
		*)
			log_error "Unsupported package manager: $pm"
			return 1
			;;
	esac
	
	log_success "OpenSSH Server installed successfully"
}

configure_ssh() {
	log_step "Configuring SSH Server"
	
	local ssh_config="/etc/ssh/sshd_config"
	
	# Backup original config
	if [[ -f "$ssh_config" ]]; then
		sudo cp "$ssh_config" "$ssh_config.backup.$(date +%Y%m%d_%H%M%S)"
		log_info "SSH config backed up"
	fi
	
	# Configure SSH with better security
	log_step "Applying SSH security configuration"
	
	# Enable password authentication (can be disabled later for key-only auth)
	sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' "$ssh_config"
	sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' "$ssh_config"
	
	# Disable root login for security
	sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' "$ssh_config"
	sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' "$ssh_config"
	
	# Change default port for security (optional)
	# sudo sed -i 's/#Port 22/Port 2222/' "$ssh_config"
	
	# Enable public key authentication
	sudo sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$ssh_config"
	
	# Disable X11 forwarding for security
	sudo sed -i 's/#X11Forwarding no/X11Forwarding no/' "$ssh_config"
	sudo sed -i 's/X11Forwarding yes/X11Forwarding no/' "$ssh_config"
	
	log_success "SSH configuration applied"
}

start_ssh_service() {
	log_step "Starting SSH service"
	
	if command -v systemctl >/dev/null 2>&1; then
		sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
		sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null || true
		log_success "SSH service started and enabled"
	else
		# Fallback for systems without systemctl
		sudo service ssh restart 2>/dev/null || sudo service sshd restart 2>/dev/null || true
		log_success "SSH service restarted"
	fi
}

verify_installation() {
	log_step "Verifying SSH installation"
	
	# Check if SSH daemon is running
	if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
		log_success "SSH service is running"
	else
		log_warning "SSH service status unclear"
	fi
	
	# Check SSH port
	local ssh_port
	ssh_port=$(grep -E "^Port" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo "22")
	log_info "SSH is configured to run on port: $ssh_port"
	
	# Show connection info
	local hostname
	hostname=$(hostname -I 2>/dev/null | awk '{print $1}' || hostname)
	log_info "You can connect via: ssh $(whoami)@$hostname"
}

main() {
	log_info "Starting SSH setup"
	
	install_ssh
	configure_ssh
	start_ssh_service
	verify_installation
	
	log_success "SSH setup completed successfully"
	log_warning "Remember to configure firewall rules if needed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
