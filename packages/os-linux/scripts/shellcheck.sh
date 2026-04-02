#!/bin/bash

# =============================================================================
# SHELLCHECK INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install ShellCheck static analysis tool for shell scripts
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_shellcheck() {
	log_step "Installing ShellCheck"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing ShellCheck installation"
		case "$pm" in
			"apt")
				sudo apt remove -y shellcheck 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm shellcheck 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y shellcheck 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install ShellCheck
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y shellcheck
			;;
		"pacman")
			sudo pacman -S --noconfirm shellcheck
			;;
		"yay")
			yay -S --noconfirm shellcheck
			;;
		"dnf")
			sudo dnf install -y shellcheck
			;;
		"zypper")
			sudo zypper install -y shellcheck
			;;
		"snap")
			sudo snap install shellcheck
			;;
		"brew")
			brew install shellcheck
			;;
		*)
			install_shellcheck_binary
			;;
	esac
	
	log_success "ShellCheck installed successfully"
}

install_shellcheck_binary() {
	log_step "Installing ShellCheck from binary release"
	
	local architecture
	local shellcheck_version="v0.9.0"
	
	architecture=$(uname -m)
	
	# Map architecture names
	case "$architecture" in
		"x86_64")
			architecture="x86_64"
			;;
		"aarch64"|"arm64")
			architecture="aarch64"
			;;
		*)
			log_error "Unsupported architecture for binary installation: $architecture"
			return 1
			;;
	esac
	
	local download_url="https://github.com/koalaman/shellcheck/releases/download/${shellcheck_version}/shellcheck-${shellcheck_version}.linux.${architecture}.tar.xz"
	
	log_info "Downloading ShellCheck ${shellcheck_version} for ${architecture}"
	
	# Download and extract
	if curl -L "$download_url" -o /tmp/shellcheck.tar.xz; then
		cd /tmp
		tar -xf shellcheck.tar.xz
		sudo mv "shellcheck-${shellcheck_version}/shellcheck" /usr/local/bin/
		sudo chmod +x /usr/local/bin/shellcheck
		rm -rf /tmp/shellcheck* "shellcheck-${shellcheck_version}"
		
		log_success "ShellCheck binary installed to /usr/local/bin/shellcheck"
	else
		log_error "Failed to download ShellCheck binary"
		return 1
	fi
}

configure_shellcheck() {
	log_step "Configuring ShellCheck"
	
	# Create a global .shellcheckrc for consistent configuration
	local shellcheck_config="$HOME/.shellcheckrc"
	
	cat > "$shellcheck_config" << 'EOF'
# ShellCheck configuration file
# Disable specific warnings that are often not relevant

# SC2034: Variable appears unused
disable=SC2034

# SC1090: Can't follow non-constant source
disable=SC1090

# SC1091: Not following sourced files
disable=SC1091

# SC2155: Declare and assign separately
disable=SC2155

# Enable external sources checking
external-sources=true

# Set shell dialect (bash is default)
shell=bash
EOF
	
	log_success "ShellCheck configuration created at $shellcheck_config"
}

create_shellcheck_aliases() {
	log_step "Creating ShellCheck aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# ShellCheck aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "ShellCheck aliases already exist in $bashrc"
		return 0
	fi
	
	# Add ShellCheck aliases
	cat >> "$bashrc" << 'EOF'

# ShellCheck aliases added by matbrgz dotfiles
alias sccheck='shellcheck'
alias scall='find . -name "*.sh" -type f -exec shellcheck {} \;'
alias scfix='shellcheck --format=diff'
alias scjson='shellcheck --format=json'
EOF
	
	log_success "ShellCheck aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying ShellCheck installation"
	
	if command -v shellcheck >/dev/null 2>&1; then
		local version
		version=$(shellcheck --version | grep "^version:" | awk '{print $2}')
		log_success "ShellCheck version: $version"
		
		# Test ShellCheck with a simple script
		local test_script="/tmp/test_shellcheck.sh"
		echo '#!/bin/bash
echo "Hello, World!"' > "$test_script"
		
		if shellcheck "$test_script" >/dev/null 2>&1; then
			log_success "ShellCheck is working correctly"
		else
			log_warning "ShellCheck test failed"
		fi
		
		rm -f "$test_script"
	else
		log_error "ShellCheck command not found"
		return 1
	fi
}

main() {
	log_info "Starting ShellCheck setup"
	
	install_shellcheck
	configure_shellcheck
	create_shellcheck_aliases
	verify_installation
	
	log_success "ShellCheck setup completed successfully"
	
	# Show usage tips
	echo
	log_info "Usage tips:"
	echo "  - Check a script: shellcheck script.sh"
	echo "  - Check all scripts: scall"
	echo "  - Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi