#!/bin/bash

# =============================================================================
# SHFMT INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install shfmt shell script formatter
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_shfmt() {
	log_step "Installing shfmt"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing shfmt installation"
		sudo rm -f /usr/local/bin/shfmt /usr/bin/shfmt
	fi
	
	# Try package manager first
	case "$pm" in
		"apt")
			# shfmt is not available in standard apt repos, install from binary
			install_shfmt_binary
			;;
		"pacman")
			sudo pacman -S --noconfirm shfmt 2>/dev/null || install_shfmt_binary
			;;
		"yay")
			yay -S --noconfirm shfmt 2>/dev/null || install_shfmt_binary
			;;
		"dnf")
			sudo dnf install -y shfmt 2>/dev/null || install_shfmt_binary
			;;
		"zypper")
			sudo zypper install -y shfmt 2>/dev/null || install_shfmt_binary
			;;
		"snap")
			sudo snap install shfmt 2>/dev/null || install_shfmt_binary
			;;
		"brew")
			brew install shfmt 2>/dev/null || install_shfmt_binary
			;;
		*)
			install_shfmt_binary
			;;
	esac
	
	log_success "shfmt installed successfully"
}

install_shfmt_binary() {
	log_step "Installing shfmt from binary release"
	
	local architecture
	local os_type
	local shfmt_version
	
	architecture=$(uname -m)
	os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
	
	# Get latest version from GitHub API
	shfmt_version=$(curl -s https://api.github.com/repos/mvdan/sh/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')
	
	if [[ -z "$shfmt_version" ]]; then
		log_warning "Could not determine latest shfmt version, using v3.7.0"
		shfmt_version="v3.7.0"
	fi
	
	# Map architecture names
	case "$architecture" in
		"x86_64")
			architecture="amd64"
			;;
		"i386"|"i686")
			architecture="386"
			;;
		"aarch64"|"arm64")
			architecture="arm64"
			;;
		"armv7l")
			architecture="arm"
			;;
		*)
			log_error "Unsupported architecture for binary installation: $architecture"
			return 1
			;;
	esac
	
	local download_url="https://github.com/mvdan/sh/releases/download/${shfmt_version}/shfmt_${shfmt_version}_${os_type}_${architecture}"
	
	log_info "Downloading shfmt ${shfmt_version} for ${os_type}_${architecture}"
	
	# Download and install
	if curl -L "$download_url" -o /tmp/shfmt; then
		sudo mv /tmp/shfmt /usr/local/bin/shfmt
		sudo chmod +x /usr/local/bin/shfmt
		
		# Create symlink for convenience
		sudo ln -sf /usr/local/bin/shfmt /usr/bin/shfmt 2>/dev/null || true
		
		log_success "shfmt binary installed to /usr/local/bin/shfmt"
	else
		log_error "Failed to download shfmt binary"
		return 1
	fi
}

configure_shfmt() {
	log_step "Configuring shfmt"
	
	# Create a .editorconfig for shell scripts formatting consistency
	local editorconfig="$HOME/.editorconfig"
	
	if [[ ! -f "$editorconfig" ]]; then
		cat > "$editorconfig" << 'EOF'
# EditorConfig configuration for consistent formatting
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.sh]
indent_style = tab
indent_size = 4

[*.{yml,yaml,json}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false
EOF
		
		log_success "EditorConfig created at $editorconfig"
	else
		log_info "EditorConfig already exists"
	fi
}

create_shfmt_aliases() {
	log_step "Creating shfmt aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# shfmt aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "shfmt aliases already exist in $bashrc"
		return 0
	fi
	
	# Add shfmt aliases
	cat >> "$bashrc" << 'EOF'

# shfmt aliases added by matbrgz dotfiles
alias shfmt-check='shfmt -d'
alias shfmt-fix='shfmt -w'
alias shfmt-all='find . -name "*.sh" -type f -exec shfmt -w {} \;'
alias shfmt-diff='shfmt -d'
EOF
	
	log_success "shfmt aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying shfmt installation"
	
	if command -v shfmt >/dev/null 2>&1; then
		local version
		version=$(shfmt --version)
		log_success "shfmt version: $version"
		
		# Test shfmt with a simple script
		local test_script="/tmp/test_shfmt.sh"
		echo '#!/bin/bash
if   [ "$1" = "test" ]; then
echo "formatting test"
fi' > "$test_script"
		
		if shfmt -d "$test_script" >/dev/null 2>&1; then
			log_success "shfmt is working correctly"
		else
			log_warning "shfmt test failed"
		fi
		
		rm -f "$test_script"
	else
		log_error "shfmt command not found"
		return 1
	fi
}

main() {
	log_info "Starting shfmt setup"
	
	install_shfmt
	configure_shfmt
	create_shfmt_aliases
	verify_installation
	
	log_success "shfmt setup completed successfully"
	
	# Show usage tips
	echo
	log_info "Usage tips:"
	echo "  - Format a script: shfmt -w script.sh"
	echo "  - Check formatting: shfmt-check script.sh"
	echo "  - Format all scripts: shfmt-all"
	echo "  - Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi