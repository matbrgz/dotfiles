#!/bin/bash

# =============================================================================
# PYTHON 3 INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install Python 3 with development tools
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_python3() {
	log_step "Installing Python 3"
	
	local pm
	pm=$(detect_package_manager)
	
	# Get Python version from version.json
	local python_version
	python_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".python")
	
	if [[ "$python_version" == "null" ]]; then
		log_warning "Python version not found in version.json, using default"
		python_version="3.11"
	fi
	
	# Extract major.minor version (e.g., "3.13.1" -> "3.13")
	local python_major_minor
	python_major_minor=$(echo "$python_version" | cut -d'.' -f1-2)
	
	log_info "Installing Python $python_major_minor"
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Python installation"
		case "$pm" in
			"apt")
				sudo apt remove -y python3 python3-* 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm python python-* 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y python3 python3-* 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install Python and development tools
	case "$pm" in
		"apt")
			# Add deadsnakes PPA for newer Python versions
			sudo apt update
			sudo apt install -y software-properties-common
			sudo add-apt-repository -y ppa:deadsnakes/ppa
			sudo apt update
			
			sudo apt install -y \
				"python${python_major_minor}" \
				"python${python_major_minor}-dev" \
				"python${python_major_minor}-venv" \
				"python${python_major_minor}-pip" \
				python3-setuptools \
				python3-wheel \
				python3-tk \
				build-essential \
				libffi-dev \
				libssl-dev \
				zlib1g-dev \
				libbz2-dev \
				libreadline-dev \
				libsqlite3-dev \
				libncurses5-dev \
				libncursesw5-dev \
				xz-utils \
				tk-dev \
				libgdbm-dev \
				libc6-dev \
				liblzma-dev
			;;
		"pacman")
			sudo pacman -S --noconfirm \
				python \
				python-pip \
				python-setuptools \
				python-wheel \
				python-virtualenv \
				tk \
				base-devel \
				openssl \
				zlib \
				bzip2 \
				readline \
				sqlite \
				ncurses \
				xz \
				gdbm
			;;
		"yay")
			yay -S --noconfirm \
				python \
				python-pip \
				python-setuptools \
				python-wheel \
				python-virtualenv \
				tk \
				base-devel
			;;
		"dnf")
			sudo dnf install -y \
				python3 \
				python3-devel \
				python3-pip \
				python3-setuptools \
				python3-wheel \
				python3-virtualenv \
				python3-tkinter \
				gcc \
				gcc-c++ \
				make \
				openssl-devel \
				zlib-devel \
				bzip2-devel \
				readline-devel \
				sqlite-devel \
				ncurses-devel \
				xz-devel \
				tk-devel \
				gdbm-devel
			;;
		"zypper")
			sudo zypper install -y \
				python3 \
				python3-devel \
				python3-pip \
				python3-setuptools \
				python3-wheel \
				python3-virtualenv \
				python3-tk \
				gcc \
				gcc-c++ \
				make
			;;
		"snap")
			sudo snap install python38 --classic
			;;
		"brew")
			brew install python@${python_major_minor}
			;;
		*)
			log_error "Unsupported package manager: $pm"
			return 1
			;;
	esac
	
	log_success "Python 3 installed successfully"
}

configure_python() {
	log_step "Configuring Python"
	
	# Create python3 symlink if needed
	if ! command -v python3 >/dev/null 2>&1; then
		# Try to find python binary
		for py_cmd in python3.13 python3.12 python3.11 python3.10 python3.9 python; do
			if command -v "$py_cmd" >/dev/null 2>&1; then
				sudo ln -sf "$(which $py_cmd)" /usr/local/bin/python3
				log_info "Created python3 symlink to $py_cmd"
				break
			fi
		done
	fi
	
	# Ensure pip is available
	if ! python3 -m pip --version >/dev/null 2>&1; then
		log_step "Installing pip"
		python3 -m ensurepip --default-pip --user
	fi
	
	# Upgrade pip
	python3 -m pip install --upgrade pip --user
	
	# Install essential Python tools
	local essential_packages=(
		"setuptools"
		"wheel"
		"virtualenv"
		"pipenv"
		"poetry"
		"black"
		"flake8"
		"pylint"
		"mypy"
		"pytest"
		"jupyter"
		"ipython"
		"requests"
		"beautifulsoup4"
		"lxml"
		"pyyaml"
		"python-dotenv"
	)
	
	log_step "Installing essential Python packages"
	for package in "${essential_packages[@]}"; do
		log_info "Installing $package"
		python3 -m pip install --user "$package" --quiet
	done
	
	log_success "Essential Python packages installed"
}

create_python_aliases() {
	log_step "Creating Python aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Python aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Python aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Python aliases
	cat >> "$bashrc" << 'EOF'

# Python aliases added by matbrgz dotfiles
alias py='python3'
alias python='python3'
alias pip='python3 -m pip'
alias venv='python3 -m venv'
alias activate='source venv/bin/activate'
alias deactivate='deactivate'
alias pstart='python3 -m http.server 8000'
alias pyserver='python3 -m http.server'
alias pytest='python3 -m pytest'
alias black='python3 -m black'
alias flake8='python3 -m flake8'
alias mypy='python3 -m mypy'
alias jupyter='python3 -m jupyter'
alias ipython='python3 -m IPython'

# Python project helpers
alias pyclean='find . -type f -name "*.pyc" -delete && find . -type d -name "__pycache__" -delete'
alias pyenv-create='python3 -m venv venv && source venv/bin/activate && pip install --upgrade pip'
alias pyrequirements='pip freeze > requirements.txt'
alias pyinstall='pip install -r requirements.txt'
EOF
	
	log_success "Python aliases added to $bashrc"
}

verify_installation() {
	log_step "Verifying Python installation"
	
	if command -v python3 >/dev/null 2>&1; then
		local python_version
		python_version=$(python3 --version)
		log_success "Python version: $python_version"
		
		# Check pip
		if python3 -m pip --version >/dev/null 2>&1; then
			local pip_version
			pip_version=$(python3 -m pip --version)
			log_success "pip version: $pip_version"
		else
			log_warning "pip not available"
		fi
		
		# Check virtual environment
		if python3 -c "import venv" 2>/dev/null; then
			log_success "venv module available"
		else
			log_warning "venv module not available"
		fi
		
		# Check essential modules
		local modules=("setuptools" "wheel" "pip" "ssl" "sqlite3" "tkinter")
		for module in "${modules[@]}"; do
			if python3 -c "import $module" 2>/dev/null; then
				log_success "$module module available"
			else
				log_warning "$module module not available"
			fi
		done
		
	else
		log_error "Python3 not found"
		return 1
	fi
}

show_usage() {
	echo
	log_info "Python usage:"
	echo "  - Run Python: py or python3"
	echo "  - Install package: pip install package_name"
	echo "  - Create virtual env: pyenv-create"
	echo "  - Activate virtual env: activate"
	echo "  - Run tests: pytest"
	echo "  - Format code: black ."
	echo "  - Lint code: flake8 ."
	echo "  - Type check: mypy ."
	echo "  - Start Jupyter: jupyter notebook"
	echo "  - Start server: pstart (port 8000)"
	echo "  - Clean bytecode: pyclean"
	echo
	log_info "Development workflow:"
	echo "  1. Create project: mkdir myproject && cd myproject"
	echo "  2. Create virtual env: pyenv-create"
	echo "  3. Install dependencies: pyinstall"
	echo "  4. Develop with: black, flake8, mypy, pytest"
}

main() {
	log_info "Starting Python 3 setup"
	
	install_python3
	configure_python
	create_python_aliases
	verify_installation
	show_usage
	
	log_success "Python 3 setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
