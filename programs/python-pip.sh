#!/bin/bash

# =============================================================================
# PYTHON PIP INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure Python pip package manager
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_pip() {
	log_step "Installing Python pip"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing pip installation"
		case "$pm" in
			"apt")
				sudo apt remove -y python3-pip python-pip 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm python-pip 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y python3-pip 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Check if Python3 is installed
	if ! command -v python3 >/dev/null 2>&1; then
		log_error "Python3 is required but not installed"
		log_info "Please install Python3 first using the python3.sh script"
		return 1
	fi
	
	# Install pip
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y python3-pip python3-setuptools python3-wheel
			;;
		"pacman")
			sudo pacman -S --noconfirm python-pip python-setuptools python-wheel
			;;
		"yay")
			yay -S --noconfirm python-pip python-setuptools python-wheel
			;;
		"dnf")
			sudo dnf install -y python3-pip python3-setuptools python3-wheel
			;;
		"zypper")
			sudo zypper install -y python3-pip python3-setuptools python3-wheel
			;;
		"snap")
			# pip is usually included with python3 snap
			log_info "pip should be included with python3 snap package"
			;;
		"brew")
			# pip is usually included with python3 from brew
			log_info "pip should be included with python3 from brew"
			;;
		*)
			install_pip_get_pip
			;;
	esac
	
	log_success "Python pip installed successfully"
}

install_pip_get_pip() {
	log_step "Installing pip using get-pip.py"
	
	local get_pip_url="https://bootstrap.pypa.io/get-pip.py"
	local temp_file="/tmp/get-pip.py"
	
	if curl -L "$get_pip_url" -o "$temp_file"; then
		python3 "$temp_file" --user
		rm -f "$temp_file"
		log_success "pip installed using get-pip.py"
	else
		log_error "Failed to download get-pip.py"
		return 1
	fi
}

configure_pip() {
	log_step "Configuring pip"
	
	# Upgrade pip to latest version
	log_step "Upgrading pip to latest version"
	python3 -m pip install --upgrade pip --user
	
	# Configure pip to use user directory by default
	local pip_conf_dir="$HOME/.config/pip"
	local pip_conf="$pip_conf_dir/pip.conf"
	
	mkdir -p "$pip_conf_dir"
	
	cat > "$pip_conf" << 'EOF'
[global]
user = true
upgrade-strategy = eager

[install]
user = true
EOF
	
	log_success "pip configuration created at $pip_conf"
	
	# Add user bin directory to PATH
	local user_bin_path="$HOME/.local/bin"
	if [[ ":$PATH:" != *":$user_bin_path:"* ]]; then
		echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
		log_success "Added $user_bin_path to PATH in .bashrc"
	else
		log_info "User bin path already in PATH"
	fi
}

install_common_packages() {
	log_step "Installing common Python packages"
	
	local common_packages=(
		"setuptools"
		"wheel"
		"virtualenv"
		"pipenv"
		"black"
		"flake8"
		"pytest"
		"requests"
		"beautifulsoup4"
		"pandas"
		"numpy"
	)
	
	for package in "${common_packages[@]}"; do
		log_info "Installing $package"
		python3 -m pip install --user "$package" --quiet
	done
	
	log_success "Common Python packages installed"
}

create_python_aliases() {
	log_step "Creating Python/pip aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Python/pip aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Python aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Python aliases
	cat >> "$bashrc" << 'EOF'

# Python/pip aliases added by matbrgz dotfiles
alias py='python3'
alias pip='python3 -m pip'
alias pip-upgrade='python3 -m pip install --upgrade pip'
alias pip-list='python3 -m pip list'
alias pip-outdated='python3 -m pip list --outdated'
alias pip-upgrade-all='python3 -m pip list --outdated --format=freeze | grep -v "^\-e" | cut -d = -f 1 | xargs -n1 python3 -m pip install -U'
alias venv-create='python3 -m venv'
alias venv-activate='source venv/bin/activate'
alias serve-here='python3 -m http.server 8000'
EOF
	
	log_success "Python aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying pip installation"
	
	if command -v python3 >/dev/null 2>&1; then
		local python_version
		python_version=$(python3 --version)
		log_success "Python version: $python_version"
	else
		log_error "Python3 not found"
		return 1
	fi
	
	if python3 -m pip --version >/dev/null 2>&1; then
		local pip_version
		pip_version=$(python3 -m pip --version)
		log_success "pip version: $pip_version"
	else
		log_error "pip not found"
		return 1
	fi
	
	# Test package installation
	if python3 -c "import setuptools" 2>/dev/null; then
		log_success "setuptools is available"
	else
		log_warning "setuptools is not available"
	fi
}

show_usage() {
	echo
	log_info "Python/pip usage:"
	echo "  - Install package: pip install package_name"
	echo "  - Install in user directory: pip install --user package_name"
	echo "  - Upgrade pip: pip-upgrade"
	echo "  - List packages: pip-list"
	echo "  - Check outdated: pip-outdated"
	echo "  - Create virtual env: venv-create myenv"
	echo "  - Activate virtual env: source myenv/bin/activate"
	echo "  - Start HTTP server: serve-here"
}

main() {
	log_info "Starting Python pip setup"
	
	install_pip
	configure_pip
	install_common_packages
	create_python_aliases
	verify_installation
	show_usage
	
	log_success "Python pip setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
