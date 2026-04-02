#!/bin/bash

# =============================================================================
# NVM (NODE VERSION MANAGER) INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install Node Version Manager for managing multiple Node.js versions
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_nvm() {
	log_step "Installing NVM (Node Version Manager)"
	
	# Get NVM version from version.json
	local nvm_version
	nvm_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".nvm")
	
	if [[ "$nvm_version" == "null" ]]; then
		log_warning "NVM version not found in version.json, using v0.39.8"
		nvm_version="0.39.8"
	fi
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing NVM installation"
		rm -rf "$HOME/.nvm" 2>/dev/null || true
		# Remove NVM lines from shell profiles
		sed -i '/NVM_DIR/d' "$HOME/.bashrc" 2>/dev/null || true
		sed -i '/nvm.sh/d' "$HOME/.bashrc" 2>/dev/null || true
		sed -i '/bash_completion/d' "$HOME/.bashrc" 2>/dev/null || true
	fi
	
	# Check if NVM is already installed
	if [[ -d "$HOME/.nvm" ]]; then
		log_info "NVM directory already exists, updating..."
	fi
	
	# Download and install NVM
	local install_url="https://raw.githubusercontent.com/nvm-sh/nvm/v${nvm_version}/install.sh"
	
	log_info "Downloading NVM v${nvm_version}"
	
	if curl -o- "$install_url" | bash; then
		log_success "NVM v${nvm_version} installed successfully"
	else
		log_error "Failed to install NVM"
		return 1
	fi
}

configure_nvm() {
	log_step "Configuring NVM"
	
	# Ensure NVM configuration is in .bashrc
	local bashrc="$HOME/.bashrc"
	local nvm_config="# NVM configuration added by matbrgz dotfiles"
	
	# Check if NVM config already exists
	if ! grep -q "$nvm_config" "$bashrc" 2>/dev/null; then
		cat >> "$bashrc" << 'EOF'

# NVM configuration added by matbrgz dotfiles
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# NVM aliases
alias nvm-install-lts='nvm install --lts'
alias nvm-use-lts='nvm use --lts'
alias nvm-install-latest='nvm install node'
alias nvm-use-latest='nvm use node'
alias nvm-list='nvm list'
alias nvm-current='nvm current'
EOF
		
		log_success "NVM configuration added to $bashrc"
	else
		log_info "NVM configuration already exists in $bashrc"
	fi
	
	# Load NVM for current session
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}

install_node_versions() {
	log_step "Installing Node.js versions"
	
	# Load NVM
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	
	if ! command -v nvm >/dev/null 2>&1; then
		log_error "NVM not available in current session"
		log_info "Please restart your shell or run: source ~/.bashrc"
		return 1
	fi
	
	# Get Node version from version.json
	local node_version
	node_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".node")
	
	if [[ "$node_version" == "null" ]]; then
		log_warning "Node version not found in version.json, installing LTS"
		# Install latest LTS
		nvm install --lts
		nvm use --lts
		nvm alias default lts/*
	else
		# Install specific version from version.json
		log_info "Installing Node.js v${node_version}"
		nvm install "$node_version"
		nvm use "$node_version"
		nvm alias default "$node_version"
	fi
	
	# Also install latest LTS as backup
	log_info "Installing latest LTS version"
	nvm install --lts
	
	log_success "Node.js versions installed"
}

install_global_packages() {
	log_step "Installing global npm packages"
	
	# Load NVM
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	
	local global_packages=(
		"yarn"
		"pnpm"
		"npm-check-updates"
		"nodemon"
		"pm2"
		"serve"
		"http-server"
		"live-server"
		"prettier"
		"eslint"
		"typescript"
		"@vue/cli"
		"@angular/cli"
		"create-react-app"
		"gatsby-cli"
		"@nestjs/cli"
	)
	
	for package in "${global_packages[@]}"; do
		log_info "Installing $package"
		npm install -g "$package" --silent
	done
	
	log_success "Global npm packages installed"
}

verify_installation() {
	log_step "Verifying NVM installation"
	
	# Load NVM
	export NVM_DIR="$HOME/.nvm"
	[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
	
	if command -v nvm >/dev/null 2>&1; then
		local nvm_version
		nvm_version=$(nvm --version)
		log_success "NVM version: $nvm_version"
		
		# Check Node.js
		if command -v node >/dev/null 2>&1; then
			local node_version
			node_version=$(node --version)
			log_success "Node.js version: $node_version"
		else
			log_warning "Node.js not available"
		fi
		
		# Check npm
		if command -v npm >/dev/null 2>&1; then
			local npm_version
			npm_version=$(npm --version)
			log_success "npm version: $npm_version"
		else
			log_warning "npm not available"
		fi
		
		# List installed versions
		log_info "Installed Node.js versions:"
		nvm list
		
	else
		log_error "NVM not found"
		log_info "Please restart your shell or run: source ~/.bashrc"
		return 1
	fi
}

show_usage() {
	echo
	log_info "NVM usage:"
	echo "  - List available versions: nvm list-remote"
	echo "  - Install latest LTS: nvm-install-lts"
	echo "  - Install specific version: nvm install 18.17.0"
	echo "  - Use version: nvm use 18.17.0"
	echo "  - Use LTS: nvm-use-lts"
	echo "  - Set default: nvm alias default 18.17.0"
	echo "  - List installed: nvm-list"
	echo "  - Current version: nvm-current"
	echo
	log_info "Global packages installed:"
	echo "  - yarn, pnpm, nodemon, pm2, serve, prettier, eslint, typescript"
	echo "  - Framework CLIs: @vue/cli, @angular/cli, create-react-app, gatsby-cli, @nestjs/cli"
}

main() {
	log_info "Starting NVM setup"
	
	install_nvm
	configure_nvm
	install_node_versions
	install_global_packages
	verify_installation
	show_usage
	
	log_success "NVM setup completed successfully"
	log_info "Restart your shell or run 'source ~/.bashrc' to use NVM"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
