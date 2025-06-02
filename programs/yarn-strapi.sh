#!/bin/bash

# =============================================================================
# STRAPI INSTALLATION SCRIPT (via Yarn/NPM)
# =============================================================================
# Author: matbrgz
# Description: Install Strapi CMS globally via package manager
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

check_dependencies() {
	log_step "Checking dependencies"
	
	# Check if Node.js is installed
	if ! command -v node >/dev/null 2>&1; then
		log_error "Node.js is required but not installed"
		log_info "Please install Node.js first using the nodejs.sh script"
		return 1
	fi
	
	# Check Node.js version (Strapi requires Node.js 18.x or higher)
	local node_version
	node_version=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
	
	if [[ "$node_version" -lt 18 ]]; then
		log_warning "Strapi recommends Node.js 18.x or higher (current: $(node --version))"
		log_info "Consider upgrading Node.js for better compatibility"
	fi
	
	# Prefer yarn over npm if available
	local package_manager=""
	if command -v yarn >/dev/null 2>&1; then
		package_manager="yarn"
		log_info "Using Yarn package manager"
	elif command -v npm >/dev/null 2>&1; then
		package_manager="npm"
		log_info "Using NPM package manager"
	else
		log_error "Neither Yarn nor NPM found"
		return 1
	fi
	
	echo "$package_manager"
}

install_strapi() {
	log_step "Installing Strapi CLI"
	
	local package_manager
	package_manager=$(check_dependencies)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Removing existing Strapi installation"
		case "$package_manager" in
			"yarn")
				yarn global remove @strapi/strapi 2>/dev/null || true
				yarn global remove strapi 2>/dev/null || true
				;;
			"npm")
				npm uninstall -g @strapi/strapi 2>/dev/null || true
				npm uninstall -g strapi 2>/dev/null || true
				;;
		esac
	fi
	
	# Install Strapi CLI
	case "$package_manager" in
		"yarn")
			yarn global add @strapi/strapi
			;;
		"npm")
			npm install -g @strapi/strapi
			;;
		*)
			log_error "Unsupported package manager: $package_manager"
			return 1
			;;
	esac
	
	log_success "Strapi CLI installed successfully"
}

create_strapi_aliases() {
	log_step "Creating Strapi aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Strapi aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Strapi aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Strapi aliases
	cat >> "$bashrc" << 'EOF'

# Strapi aliases added by matbrgz dotfiles
alias strapi-new='npx create-strapi-app'
alias strapi-dev='npm run develop'
alias strapi-build='npm run build'
alias strapi-start='npm run start'
EOF
	
	log_success "Strapi aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying Strapi installation"
	
	if command -v strapi >/dev/null 2>&1; then
		local version
		version=$(strapi version 2>/dev/null || echo "unknown")
		log_success "Strapi CLI version: $version"
		
		# Test if we can use create-strapi-app
		if command -v npx >/dev/null 2>&1; then
			log_success "npx is available for creating new Strapi projects"
		else
			log_warning "npx is not available"
		fi
	else
		log_error "Strapi CLI not found"
		log_info "Try running 'npx create-strapi-app my-project' to create a new project"
		return 1
	fi
}

show_usage() {
	echo
	log_info "Strapi usage:"
	echo "  - Create new project: npx create-strapi-app my-project"
	echo "  - Or use alias: strapi-new my-project"
	echo "  - Start development: cd my-project && npm run develop"
	echo "  - Or use alias: strapi-dev"
	echo "  - Build for production: npm run build"
	echo "  - Start production: npm run start"
	echo
	log_info "Strapi admin panel will be available at: http://localhost:1337/admin"
}

main() {
	log_info "Starting Strapi setup"
	
	install_strapi
	create_strapi_aliases
	verify_installation
	show_usage
	
	log_success "Strapi setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
