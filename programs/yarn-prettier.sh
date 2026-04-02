#!/bin/bash

# =============================================================================
# PRETTIER INSTALLATION SCRIPT (via Yarn/NPM)
# =============================================================================
# Author: matbrgz
# Description: Install Prettier code formatter globally
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
		log_info "Please install Node.js first using the nvm.sh or nodejs.sh script"
		return 1
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

install_prettier() {
	log_step "Installing Prettier"
	
	local package_manager
	package_manager=$(check_dependencies)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Removing existing Prettier installation"
		case "$package_manager" in
			"yarn")
				yarn global remove prettier 2>/dev/null || true
				;;
			"npm")
				npm uninstall -g prettier 2>/dev/null || true
				;;
		esac
	fi
	
	# Install Prettier globally
	case "$package_manager" in
		"yarn")
			yarn global add prettier
			;;
		"npm")
			npm install -g prettier
			;;
		*)
			log_error "Unsupported package manager: $package_manager"
			return 1
			;;
	esac
	
	log_success "Prettier installed successfully"
}

configure_prettier() {
	log_step "Configuring Prettier"
	
	# Create global Prettier configuration
	local prettier_config="$HOME/.prettierrc"
	
	if [[ ! -f "$prettier_config" ]]; then
		cat > "$prettier_config" << 'EOF'
{
  "semi": true,
  "trailingComma": "es5",
  "singleQuote": true,
  "printWidth": 80,
  "tabWidth": 2,
  "useTabs": false,
  "bracketSpacing": true,
  "bracketSameLine": false,
  "arrowParens": "avoid",
  "endOfLine": "lf",
  "quoteProps": "as-needed",
  "jsxSingleQuote": true,
  "proseWrap": "preserve",
  "htmlWhitespaceSensitivity": "css",
  "embeddedLanguageFormatting": "auto"
}
EOF
		
		log_success "Prettier configuration created at $prettier_config"
	else
		log_info "Prettier configuration already exists"
	fi
	
	# Create .prettierignore file
	local prettier_ignore="$HOME/.prettierignore"
	
	if [[ ! -f "$prettier_ignore" ]]; then
		cat > "$prettier_ignore" << 'EOF'
# Dependencies
node_modules/
.pnp
.pnp.js

# Production builds
build/
dist/
out/

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Logs
npm-debug.log*
yarn-debug.log*
yarn-error.log*
lerna-debug.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Coverage directory used by tools like istanbul
coverage/
*.lcov

# Dependency directories
node_modules/
jspm_packages/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# Stores VSCode versions used for testing VSCode extensions
.vscode-test

# yarn v2
.yarn/cache
.yarn/unplugged
.yarn/build-state.yml
.yarn/install-state.gz
.pnp.*

# Generated files
*.min.js
*.min.css
bundle.js
bundle.css

# Temporary files
*.tmp
*.temp
.cache/

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.idea/
*.swp
*.swo
*~

# Package files
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip
EOF
		
		log_success "Prettier ignore file created at $prettier_ignore"
	else
		log_info "Prettier ignore file already exists"
	fi
}

create_prettier_aliases() {
	log_step "Creating Prettier aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# Prettier aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "Prettier aliases already exist in $bashrc"
		return 0
	fi
	
	# Add Prettier aliases
	cat >> "$bashrc" << 'EOF'

# Prettier aliases added by matbrgz dotfiles
alias prettier-check='prettier --check'
alias prettier-write='prettier --write'
alias prettier-all='prettier --write "**/*.{js,jsx,ts,tsx,json,css,md,html,yml,yaml}"'
alias prettier-js='prettier --write "**/*.{js,jsx,ts,tsx}"'
alias prettier-css='prettier --write "**/*.{css,scss,sass,less}"'
alias prettier-md='prettier --write "**/*.md"'
alias prettier-json='prettier --write "**/*.json"'
alias prettier-config='prettier --write .prettierrc'

# Prettier project helpers
alias prettier-init='echo "{}" > .prettierrc && echo "node_modules/" > .prettierignore'
alias prettier-check-all='prettier --check "**/*.{js,jsx,ts,tsx,json,css,md,html,yml,yaml}"'
EOF
	
	log_success "Prettier aliases added to $bashrc"
}

install_editor_plugins() {
	log_step "Installing editor plugins information"
	
	echo
	log_info "Editor plugin installation commands:"
	echo
	echo "VS Code:"
	echo "  code --install-extension esbenp.prettier-vscode"
	echo
	echo "Vim/Neovim:"
	echo "  :PlugInstall prettier/vim-prettier"
	echo
	echo "Sublime Text:"
	echo "  Package Control: Install JsPrettier"
	echo
	echo "Atom:"
	echo "  apm install prettier-atom"
	echo
	echo "WebStorm/IntelliJ:"
	echo "  Built-in support, enable in Settings > Languages & Frameworks > JavaScript > Prettier"
}

verify_installation() {
	log_step "Verifying Prettier installation"
	
	if command -v prettier >/dev/null 2>&1; then
		local version
		version=$(prettier --version)
		log_success "Prettier version: $version"
		
		# Test Prettier with a sample file
		local test_file="/tmp/test_prettier.js"
		echo 'const hello = "world";console.log(hello)' > "$test_file"
		
		if prettier --check "$test_file" >/dev/null 2>&1; then
			log_success "Prettier is working correctly"
		else
			log_info "Prettier detected formatting issues (this is normal for the test)"
		fi
		
		rm -f "$test_file"
	else
		log_error "Prettier command not found"
		return 1
	fi
}

show_usage() {
	echo
	log_info "Prettier usage:"
	echo "  - Check formatting: prettier-check file.js"
	echo "  - Format file: prettier-write file.js"
	echo "  - Format all files: prettier-all"
	echo "  - Format JS/TS only: prettier-js"
	echo "  - Format CSS only: prettier-css"
	echo "  - Format Markdown: prettier-md"
	echo "  - Check all files: prettier-check-all"
	echo
	log_info "Project setup:"
	echo "  - Initialize config: prettier-init"
	echo "  - Custom config: edit .prettierrc"
	echo "  - Ignore files: edit .prettierignore"
	echo
	log_info "Configuration:"
	echo "  - Global config: $HOME/.prettierrc"
	echo "  - Global ignore: $HOME/.prettierignore"
	echo "  - Project config: .prettierrc (overrides global)"
}

main() {
	log_info "Starting Prettier setup"
	
	install_prettier
	configure_prettier
	create_prettier_aliases
	install_editor_plugins
	verify_installation
	show_usage
	
	log_success "Prettier setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi