#!/bin/bash

# PyEnv - Python Version Manager Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="PyEnv Python Version Manager"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_pyenv_version() {
	pyenv_version=$(get_json_value "pyenv")
	if [[ -z "$pyenv_version" || "$pyenv_version" == "null" ]]; then
		pyenv_version="2.4.22"
	fi
	echo "$pyenv_version"
}

get_python_version() {
	python_version=$(get_json_value "python")
	if [[ -z "$python_version" || "$python_version" == "null" ]]; then
		python_version="3.13.1"
	fi
	echo "$python_version"
}

# Check if PyEnv is already installed
check_pyenv_installation() {
	if [[ -d "$HOME/.pyenv" ]] && command -v pyenv >/dev/null 2>&1; then
		log_warning "PyEnv is already installed"
		pyenv --version
		return 0
	fi
	return 1
}

# Install build dependencies
install_build_dependencies() {
	log_step "Installing Python build dependencies"
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			sudo apt-get update
			sudo apt-get install -y build-essential libssl-dev zlib1g-dev \
				libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm \
				libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
				libffi-dev liblzma-dev
			;;
		yay|pacman)
			sudo pacman -S --needed --noconfirm base-devel openssl zlib bzip2 \
				readline sqlite curl llvm ncurses xz tk libxml2 xmlsec libffi xz
			;;
		dnf)
			sudo dnf groupinstall -y "Development Tools"
			sudo dnf install -y openssl-devel bzip2-devel libffi-devel \
				zlib-devel readline-devel sqlite-devel wget curl llvm \
				ncurses-devel xz-devel tk-devel libxml2-devel xmlsec1-devel
			;;
		zypper)
			sudo zypper install -y -t pattern devel_basis
			sudo zypper install -y libopenssl-devel libbz2-devel libffi-devel \
				zlib-devel readline-devel sqlite3-devel wget curl llvm \
				ncurses-devel xz-devel tk-devel libxml2-devel xmlsec1-devel
			;;
		brew)
			brew install openssl readline sqlite3 xz zlib tcl-tk libffi
			;;
		*)
			log_warning "Package manager not supported for dependency installation"
			;;
	esac
}

# Clone and install PyEnv
install_pyenv() {
	log_step "Installing PyEnv"
	
	# Remove existing installation if corrupted
	if [[ -d "$HOME/.pyenv" ]] && ! command -v pyenv >/dev/null 2>&1; then
		log_warning "Removing corrupted PyEnv installation"
		rm -rf "$HOME/.pyenv"
	fi
	
	# Clone PyEnv repository
	if [[ ! -d "$HOME/.pyenv" ]]; then
		git clone https://github.com/pyenv/pyenv.git "$HOME/.pyenv"
		
		# Build PyEnv for better performance (optional but recommended)
		cd "$HOME/.pyenv" && src/configure && make -C src || true
	fi
}

# Configure shell environment
configure_shell_environment() {
	log_step "Configuring shell environment"
	
	local shell_config
	case "${SHELL##*/}" in
		bash)
			shell_config="$HOME/.bashrc"
			;;
		zsh)
			shell_config="$HOME/.zshrc"
			;;
		fish)
			shell_config="$HOME/.config/fish/config.fish"
			;;
		*)
			shell_config="$HOME/.bashrc"
			;;
	esac
	
	# Create backup of shell config
	if [[ -f "$shell_config" ]]; then
		cp "$shell_config" "${shell_config}.backup.$(date +%Y%m%d_%H%M%S)"
	fi
	
	# Add PyEnv to shell configuration
	local pyenv_config="
# PyEnv Configuration
export PYENV_ROOT=\"\$HOME/.pyenv\"
[[ -d \$PYENV_ROOT/bin ]] && export PATH=\"\$PYENV_ROOT/bin:\$PATH\"
eval \"\$(pyenv init -)\"
"
	
	if ! grep -q "PYENV_ROOT" "$shell_config" 2>/dev/null; then
		echo "$pyenv_config" >> "$shell_config"
		log_success "Added PyEnv configuration to $shell_config"
	fi
	
	# Source the configuration for current session
	export PYENV_ROOT="$HOME/.pyenv"
	export PATH="$PYENV_ROOT/bin:$PATH"
	if command -v pyenv >/dev/null 2>&1; then
		eval "$(pyenv init -)"
	fi
}

# Install Python versions
install_python_versions() {
	log_step "Installing Python versions"
	
	local python_version
	python_version=$(get_python_version)
	
	# Verify PyEnv is working
	if ! command -v pyenv >/dev/null 2>&1; then
		log_error "PyEnv not found in PATH. Please restart your shell."
		return 1
	fi
	
	# Install latest Python version
	log_step "Installing Python $python_version"
	if ! pyenv versions --bare | grep -q "^${python_version}$"; then
		pyenv install "$python_version"
		log_success "Python $python_version installed successfully"
	else
		log_warning "Python $python_version is already installed"
	fi
	
	# Set global Python version
	pyenv global "$python_version"
	pyenv rehash
	
	# Verify installation
	log_step "Verifying Python installation"
	python --version
	pip --version
}

# Install useful Python packages
install_python_packages() {
	log_step "Installing essential Python packages"
	
	# Upgrade pip first
	python -m pip install --upgrade pip
	
	# Essential packages
	local packages=(
		"virtualenv"
		"virtualenvwrapper"
		"pipenv"
		"poetry"
		"black"
		"flake8"
		"pylint"
		"mypy"
		"pytest"
		"pytest-cov"
		"jupyter"
		"ipython"
		"requests"
		"numpy"
		"pandas"
	)
	
	for package in "${packages[@]}"; do
		if ! python -m pip show "$package" >/dev/null 2>&1; then
			python -m pip install "$package"
		fi
	done
	
	log_success "Essential Python packages installed"
}

# Create useful aliases
create_aliases() {
	log_step "Creating PyEnv aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for PyEnv
	local pyenv_aliases="
# PyEnv Aliases
alias py='python'
alias py3='python3'
alias pip3='pip'
alias pyver='python --version'
alias pylist='pyenv versions'
alias pylocal='pyenv local'
alias pyglobal='pyenv global'
alias pyinstall='pyenv install'
alias pyuninstall='pyenv uninstall'
alias pyrehash='pyenv rehash'
alias pyvenv='python -m venv'
alias pyactivate='source ./venv/bin/activate'
alias pyfreeze='pip freeze > requirements.txt'
alias pyreqs='pip install -r requirements.txt'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "PyEnv Aliases" "$alias_file"; then
			echo "$pyenv_aliases" >> "$alias_file"
		fi
	else
		echo "$pyenv_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "PyEnv aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying PyEnv installation"
	
	if command -v pyenv >/dev/null 2>&1; then
		log_success "PyEnv installed successfully!"
		echo "  Version: $(pyenv --version)"
		echo "  Global Python: $(pyenv global)"
		echo "  Available versions: $(pyenv versions --bare | tr '\n' ' ')"
		return 0
	else
		log_error "PyEnv installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

PyEnv Usage Instructions:
========================

Basic Commands:
  pyenv install <version>     Install Python version
  pyenv versions              List installed versions
  pyenv global <version>      Set global Python version
  pyenv local <version>       Set local Python version for project
  pyenv shell <version>       Set Python version for current shell

Example Usage:
  pyenv install 3.12.0       Install Python 3.12.0
  pyenv global 3.12.0        Use Python 3.12.0 globally
  pyenv local 3.11.5         Use Python 3.11.5 in current directory

Virtual Environments:
  python -m venv myenv        Create virtual environment
  source myenv/bin/activate   Activate virtual environment
  deactivate                  Deactivate virtual environment

Useful Aliases:
  py, py3                     Python shortcuts
  pyver                       Check Python version
  pylist                      List installed versions
  pyvenv                      Create virtual environment
  pyactivate                  Activate local venv
  pyfreeze                    Export requirements.txt
  pyreqs                      Install from requirements.txt

Configuration Files:
  ~/.pyenv/                   PyEnv installation directory
  ~/.python-version           Global Python version file
  .python-version             Local Python version file (per project)

For more information: https://github.com/pyenv/pyenv

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_pyenv_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install dependencies and PyEnv
	install_build_dependencies
	install_pyenv
	configure_shell_environment
	
	# Wait a moment for shell configuration
	sleep 2
	
	# Install Python and packages
	install_python_versions
	install_python_packages
	
	# Setup aliases and verify
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Please restart your shell or run: source ~/.bashrc"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
