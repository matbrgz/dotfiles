#!/bin/bash

# RVM - Ruby Version Manager Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="RVM Ruby Version Manager"
CONFIG_FILE="$HOME/.bashrc"
RVM_INSTALL_URL="https://get.rvm.io"

# Get version from version.json
get_rvm_version() {
	rvm_version=$(get_json_value "rvm")
	if [[ -z "$rvm_version" || "$rvm_version" == "null" ]]; then
		rvm_version="1.29.12"
	fi
	echo "$rvm_version"
}

get_ruby_version() {
	ruby_version=$(get_json_value "ruby")
	if [[ -z "$ruby_version" || "$ruby_version" == "null" ]]; then
		ruby_version="3.3.6"
	fi
	echo "$ruby_version"
}

# Check if RVM is already installed
check_rvm_installation() {
	if [[ -d "$HOME/.rvm" ]] && command -v rvm >/dev/null 2>&1; then
		log_warning "RVM is already installed"
		rvm --version
		return 0
	fi
	return 1
}

# Install dependencies
install_dependencies() {
	log_step "Installing RVM dependencies"
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			sudo apt-get update
			sudo apt-get install -y gnupg2 curl build-essential \
				libssl-dev libreadline-dev zlib1g-dev autoconf \
				bison libyaml-dev libreadline-dev libncurses5-dev \
				libffi-dev libgdbm-dev dirmngr software-properties-common
			;;
		yay|pacman)
			sudo pacman -S --needed --noconfirm base-devel curl gnupg \
				openssl readline zlib autoconf bison libyaml \
				libffi gdbm ncurses
			;;
		dnf)
			sudo dnf groupinstall -y "Development Tools"
			sudo dnf install -y gnupg2 curl openssl-devel \
				readline-devel zlib-devel autoconf bison \
				libyaml-devel libffi-devel gdbm-devel ncurses-devel
			;;
		zypper)
			sudo zypper install -y -t pattern devel_basis
			sudo zypper install -y gpg2 curl libopenssl-devel \
				readline-devel zlib-devel autoconf bison \
				libyaml-devel libffi-devel gdbm-devel ncurses-devel
			;;
		brew)
			brew install gnupg curl openssl readline libyaml libffi
			;;
		*)
			log_warning "Package manager not supported for dependency installation"
			;;
	esac
}

# Install GPG keys for RVM
install_gpg_keys() {
	log_step "Installing RVM GPG keys"
	
	# Import RVM GPG keys
	local keys=(
		"409B6B1796C275462A1703113804BB82D39DC0E3"
		"7D2BAF1CF37B13E2069D6956105BD0E739499BDB"
	)
	
	for key in "${keys[@]}"; do
		if ! gpg --list-keys "$key" >/dev/null 2>&1; then
			log_step "Importing GPG key: $key"
			if ! gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$key"; then
				# Try alternative keyserver
				gpg --keyserver hkp://keys.gnupg.net --recv-keys "$key" || {
					log_warning "Failed to import GPG key $key, trying without verification"
					return 0
				}
			fi
		fi
	done
}

# Download and install RVM
install_rvm() {
	log_step "Installing RVM"
	
	# Remove existing installation if corrupted
	if [[ -d "$HOME/.rvm" ]] && ! command -v rvm >/dev/null 2>&1; then
		log_warning "Removing corrupted RVM installation"
		rm -rf "$HOME/.rvm"
	fi
	
	# Download and install RVM
	if [[ ! -d "$HOME/.rvm" ]]; then
		log_step "Downloading RVM installer"
		if curl -sSL "$RVM_INSTALL_URL" | bash -s stable; then
			log_success "RVM installed successfully"
		else
			log_error "Failed to install RVM"
			return 1
		fi
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
	
	# Add RVM to shell configuration
	local rvm_config="
# RVM Configuration
export PATH=\"\$PATH:\$HOME/.rvm/bin\"
[[ -s \"\$HOME/.rvm/scripts/rvm\" ]] && source \"\$HOME/.rvm/scripts/rvm\"
"
	
	if ! grep -q "\.rvm/scripts/rvm" "$shell_config" 2>/dev/null; then
		echo "$rvm_config" >> "$shell_config"
		log_success "Added RVM configuration to $shell_config"
	fi
	
	# Source RVM for current session
	export PATH="$PATH:$HOME/.rvm/bin"
	if [[ -s "$HOME/.rvm/scripts/rvm" ]]; then
		source "$HOME/.rvm/scripts/rvm"
	fi
}

# Install Ruby versions
install_ruby_versions() {
	log_step "Installing Ruby versions"
	
	local ruby_version
	ruby_version=$(get_ruby_version)
	
	# Verify RVM is working
	if ! command -v rvm >/dev/null 2>&1; then
		log_error "RVM not found in PATH. Please restart your shell."
		return 1
	fi
	
	# Install latest Ruby version
	log_step "Installing Ruby $ruby_version"
	if ! rvm list | grep -q "$ruby_version"; then
		rvm install "$ruby_version"
		log_success "Ruby $ruby_version installed successfully"
	else
		log_warning "Ruby $ruby_version is already installed"
	fi
	
	# Set default Ruby version
	rvm use "$ruby_version" --default
	
	# Verify installation
	log_step "Verifying Ruby installation"
	ruby --version
	gem --version
}

# Install useful Ruby gems
install_ruby_gems() {
	log_step "Installing essential Ruby gems"
	
	# Update RubyGems
	gem update --system
	
	# Essential gems
	local gems=(
		"bundler"
		"rails"
		"rake"
		"rubocop"
		"pry"
		"rspec"
		"minitest"
		"jekyll"
		"sass"
		"nokogiri"
		"json"
		"httparty"
		"sinatra"
	)
	
	for gem_name in "${gems[@]}"; do
		if ! gem list -i "$gem_name" >/dev/null 2>&1; then
			gem install "$gem_name" --no-document
		fi
	done
	
	log_success "Essential Ruby gems installed"
}

# Create useful aliases
create_aliases() {
	log_step "Creating RVM aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for RVM
	local rvm_aliases="
# RVM Aliases
alias rb='ruby'
alias rbv='ruby --version'
alias gemv='gem --version'
alias gemlist='gem list'
alias geminstall='gem install'
alias gemuninstall='gem uninstall'
alias rvmlist='rvm list'
alias rvmuse='rvm use'
alias rvminstall='rvm install'
alias rvmuninstall='rvm uninstall'
alias rvmdefault='rvm use --default'
alias bundle='bundle'
alias bundleinstall='bundle install'
alias bundleupdate='bundle update'
alias rails='rails'
alias railsnew='rails new'
alias railsserver='rails server'
alias railsconsole='rails console'
alias rake='rake'
alias rspec='rspec'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "RVM Aliases" "$alias_file"; then
			echo "$rvm_aliases" >> "$alias_file"
		fi
	else
		echo "$rvm_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "RVM aliases created"
}

# Create sample Ruby project
create_sample_project() {
	log_step "Creating sample Ruby project"
	
	local project_dir="$HOME/ruby-sample-project"
	
	if [[ ! -d "$project_dir" ]]; then
		mkdir -p "$project_dir"
		cd "$project_dir"
		
		# Create Gemfile
		cat > Gemfile << 'EOF'
source 'https://rubygems.org'

gem 'httparty'
gem 'json'
gem 'rspec', group: :test

ruby '3.3.6'
EOF
		
		# Create sample Ruby application
		cat > app.rb << 'EOF'
#!/usr/bin/env ruby

require 'httparty'
require 'json'

class WeatherApp
  BASE_URL = 'https://api.github.com'
  
  def self.get_user_info(username)
    response = HTTParty.get("#{BASE_URL}/users/#{username}")
    
    if response.success?
      user_data = JSON.parse(response.body)
      puts "User: #{user_data['name'] || user_data['login']}"
      puts "Public repos: #{user_data['public_repos']}"
      puts "Followers: #{user_data['followers']}"
      puts "Following: #{user_data['following']}"
    else
      puts "Error: #{response.code} - #{response.message}"
    end
  rescue StandardError => e
    puts "Error: #{e.message}"
  end
end

# Example usage
if ARGV.length > 0
  WeatherApp.get_user_info(ARGV[0])
else
  puts "Usage: ruby app.rb <github_username>"
  puts "Example: ruby app.rb octocat"
end
EOF
		
		# Create spec file
		mkdir -p spec
		cat > spec/app_spec.rb << 'EOF'
require 'rspec'
require_relative '../app'

describe WeatherApp do
  describe '.get_user_info' do
    it 'should handle valid username' do
      expect { WeatherApp.get_user_info('octocat') }.not_to raise_error
    end
    
    it 'should handle invalid username gracefully' do
      expect { WeatherApp.get_user_info('nonexistentuser123456789') }.not_to raise_error
    end
  end
end
EOF
		
		# Create README
		cat > README.md << 'EOF'
# Ruby Sample Project

A simple Ruby application demonstrating HTTP requests and JSON parsing.

## Setup

```bash
bundle install
```

## Usage

```bash
ruby app.rb <github_username>
```

## Testing

```bash
rspec
```
EOF
		
		chmod +x app.rb
		log_success "Sample Ruby project created at $project_dir"
	fi
}

# Verify installation
verify_installation() {
	log_step "Verifying RVM installation"
	
	if command -v rvm >/dev/null 2>&1; then
		log_success "RVM installed successfully!"
		echo "  Version: $(rvm --version | head -n1)"
		echo "  Current Ruby: $(rvm current)"
		echo "  Available Rubies: $(rvm list | grep -E 'ruby-|jruby-' | tr '\n' ' ')"
		return 0
	else
		log_error "RVM installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

RVM Usage Instructions:
======================

Basic Commands:
  rvm install <version>       Install Ruby version
  rvm list                    List installed versions
  rvm use <version>           Use Ruby version for current shell
  rvm use <version> --default Set default Ruby version
  rvm uninstall <version>     Uninstall Ruby version

Example Usage:
  rvm install 3.2.0          Install Ruby 3.2.0
  rvm use 3.2.0 --default    Use Ruby 3.2.0 as default
  rvm list                    List all installed versions

Gemsets (isolated gem environments):
  rvm gemset create myapp     Create gemset
  rvm gemset use myapp        Use gemset
  rvm use 3.2.0@myapp         Use Ruby version with gemset

Useful Aliases:
  rb                          Ruby shortcut
  rbv                         Check Ruby version
  rvmlist                     List installed versions
  rvmuse                      Use Ruby version
  bundle                      Bundler commands
  rails                       Rails commands

Configuration Files:
  ~/.rvm/                     RVM installation directory
  ~/.rvmrc                    RVM configuration file
  .ruby-version               Project Ruby version file
  Gemfile                     Project gem dependencies

For more information: https://rvm.io/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_rvm_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install dependencies and RVM
	install_dependencies
	install_gpg_keys
	install_rvm
	configure_shell_environment
	
	# Wait a moment for shell configuration
	sleep 2
	
	# Install Ruby and gems
	install_ruby_versions
	install_ruby_gems
	
	# Setup aliases and create sample project
	create_aliases
	create_sample_project
	
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
