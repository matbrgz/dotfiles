#!/bin/bash

# =============================================================================
# MOSH INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install Mosh (mobile shell) for better SSH connections
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_mosh() {
	log_step "Installing Mosh"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Mosh installation"
		case "$pm" in
			"apt")
				sudo apt remove -y mosh 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm mosh 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y mosh 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install dependencies first
	install_dependencies
	
	# Install Mosh
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y mosh
			;;
		"pacman")
			sudo pacman -S --noconfirm mosh
			;;
		"yay")
			yay -S --noconfirm mosh
			;;
		"dnf")
			sudo dnf install -y mosh
			;;
		"zypper")
			sudo zypper install -y mosh
			;;
		"snap")
			sudo snap install mosh --classic
			;;
		"brew")
			brew install mosh
			;;
		*)
			install_mosh_from_source
			;;
	esac
	
	log_success "Mosh installed successfully"
}

install_dependencies() {
	log_step "Installing Mosh dependencies"
	
	local pm
	pm=$(detect_package_manager)
	
	case "$pm" in
		"apt")
			sudo apt install -y \
				build-essential \
				pkg-config \
				libprotobuf-dev \
				protobuf-compiler \
				libncurses5-dev \
				zlib1g-dev \
				libssl-dev \
				perl
			;;
		"pacman")
			sudo pacman -S --noconfirm \
				base-devel \
				protobuf \
				ncurses \
				zlib \
				openssl \
				perl
			;;
		"dnf")
			sudo dnf install -y \
				gcc-c++ \
				pkg-config \
				protobuf-devel \
				protobuf-compiler \
				ncurses-devel \
				zlib-devel \
				openssl-devel \
				perl
			;;
		*)
			log_info "Dependency installation not configured for $pm"
			;;
	esac
}

install_mosh_from_source() {
	log_step "Installing Mosh from source"
	
	local mosh_version="1.4.0"
	local download_url="https://github.com/mobile-shell/mosh/releases/download/mosh-${mosh_version}/mosh-${mosh_version}.tar.gz"
	local temp_dir="/tmp/mosh-build"
	
	# Create temp directory
	mkdir -p "$temp_dir"
	cd "$temp_dir"
	
	# Download and extract
	if curl -L "$download_url" -o "mosh-${mosh_version}.tar.gz"; then
		tar -xzf "mosh-${mosh_version}.tar.gz"
		cd "mosh-${mosh_version}"
		
		# Configure, compile and install
		./configure --prefix=/usr/local
		make -j$(nproc)
		sudo make install
		
		# Update library cache
		sudo ldconfig 2>/dev/null || true
		
		log_success "Mosh compiled and installed from source"
	else
		log_error "Failed to download Mosh source"
		return 1
	fi
	
	# Cleanup
	rm -rf "$temp_dir"
}

configure_firewall() {
	log_step "Configuring firewall for Mosh"
	
	# Mosh uses UDP ports 60000-61000
	if command -v ufw >/dev/null 2>&1; then
		log_step "Configuring UFW firewall"
		sudo ufw allow 60000:61000/udp comment "Mosh" 2>/dev/null || true
		log_success "UFW rules added for Mosh"
	elif command -v firewall-cmd >/dev/null 2>&1; then
		log_step "Configuring firewalld"
		sudo firewall-cmd --permanent --add-port=60000-61000/udp 2>/dev/null || true
		sudo firewall-cmd --reload 2>/dev/null || true
		log_success "firewalld rules added for Mosh"
	else
		log_warning "No supported firewall found"
		log_info "Manually open UDP ports 60000-61000 if using a firewall"
	fi
}

create_mosh_aliases() {
	log_step "Creating Mosh aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Mosh aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Mosh aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Mosh aliases
	cat >> "$bashrc" << 'EOF'

# Mosh aliases added by matbrgz dotfiles
alias mosh-server='mosh-server new -s'
alias mosh-local='mosh localhost'
EOF
	
	log_success "Mosh aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying Mosh installation"
	
	if command -v mosh >/dev/null 2>&1; then
		local version
		version=$(mosh --version 2>&1 | head -n1)
		log_success "Mosh version: $version"
	else
		log_error "Mosh command not found"
		return 1
	fi
	
	if command -v mosh-server >/dev/null 2>&1; then
		log_success "mosh-server is available"
	else
		log_warning "mosh-server not found"
	fi
	
	if command -v mosh-client >/dev/null 2>&1; then
		log_success "mosh-client is available"
	else
		log_warning "mosh-client not found"
	fi
}

show_usage() {
	echo
	log_info "Mosh usage:"
	echo "  - Connect to server: mosh user@hostname"
	echo "  - Connect with SSH port: mosh --ssh='ssh -p 2222' user@hostname"
	echo "  - Local connection: mosh-local"
	echo "  - Manual server start: mosh-server"
	echo
	log_info "Mosh advantages:"
	echo "  - Survives network disconnections"
	echo "  - Roaming between networks"
	echo "  - Local echo for low-latency typing"
	echo "  - Intelligent local editing"
	echo
	log_warning "Note: Mosh requires UDP ports 60000-61000 to be open"
}

main() {
	log_info "Starting Mosh setup"
	
	install_mosh
	configure_firewall
	create_mosh_aliases
	verify_installation
	show_usage
	
	log_success "Mosh setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
