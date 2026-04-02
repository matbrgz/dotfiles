#!/bin/bash

# =============================================================================
# GIT INSTALLATION AND CONFIGURATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure Git with modern settings
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_git() {
    log_step "Installing Git"
    
    local pm
    pm=$(detect_package_manager)
    
    case "$pm" in
        "apt")
            sudo apt update && sudo apt install -y git git-lfs
            ;;
        "pacman")
            sudo pacman -S --noconfirm git git-lfs
            ;;
        "yay")
            yay -S --noconfirm git git-lfs
            ;;
        "dnf")
            sudo dnf install -y git git-lfs
            ;;
        "zypper")
            sudo zypper install -y git git-lfs
            ;;
        "brew")
            brew install git git-lfs
            ;;
        *)
            log_error "Unsupported package manager: $pm"
            return 1
            ;;
    esac
    
    log_success "Git installed successfully"
}

configure_git() {
    log_step "Configuring Git"
    
    # Get personal settings
    local name email
    name=$(get_json_value "$PROJECT_ROOT/settings.json" ".personal.name")
    email=$(get_json_value "$PROJECT_ROOT/settings.json" ".personal.email")
    
    if [[ "$name" == "null" || "$email" == "null" ]]; then
        log_warning "Personal name or email not set in settings.json"
        return 1
    fi
    
    # Basic configuration
    git config --global user.name "$name"
    git config --global user.email "$email"
    
    # Modern Git settings
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global push.default simple
    git config --global core.autocrlf input
    git config --global core.safecrlf warn
    git config --global core.editor "vim"
    
    # Enhanced diff and merge settings
    git config --global diff.tool vimdiff
    git config --global merge.tool vimdiff
    git config --global difftool.prompt false
    
    # Color settings
    git config --global color.ui auto
    git config --global color.branch auto
    git config --global color.diff auto
    git config --global color.status auto
    
    # Useful aliases
    git config --global alias.st status
    git config --global alias.co checkout
    git config --global alias.br branch
    git config --global alias.ci commit
    git config --global alias.unstage 'reset HEAD --'
    git config --global alias.last 'log -1 HEAD'
    git config --global alias.visual '!gitk'
    git config --global alias.graph 'log --oneline --graph --decorate --all'
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    
    # Performance settings
    git config --global core.preloadindex true
    git config --global core.fscache true
    git config --global gc.auto 256
    
    # Initialize Git LFS
    git lfs install
    
    log_success "Git configured successfully"
    log_info "User: $name <$email>"
}

setup_ssh_key() {
    log_step "Setting up SSH key for Git"
    
    local email
    email=$(get_json_value "$PROJECT_ROOT/settings.json" ".personal.email")
    
    if [[ "$email" == "null" ]]; then
        log_warning "Email not set in settings.json, skipping SSH key setup"
        return 1
    fi
    
    local ssh_dir="$HOME/.ssh"
    local ssh_key="$ssh_dir/id_rsa"
    
    # Create SSH directory if it doesn't exist
    if [[ ! -d "$ssh_dir" ]]; then
        mkdir -p "$ssh_dir"
        chmod 700 "$ssh_dir"
    fi
    
    # Generate SSH key if it doesn't exist
    if [[ ! -f "$ssh_key" ]]; then
        log_info "Generating SSH key for $email"
        ssh-keygen -t rsa -b 4096 -C "$email" -f "$ssh_key" -N ""
        chmod 600 "$ssh_key"
        chmod 644 "$ssh_key.pub"
        
        log_success "SSH key generated successfully"
        log_info "Public key location: $ssh_key.pub"
        
        # Start SSH agent and add key
        eval "$(ssh-agent -s)"
        ssh-add "$ssh_key"
        
        # Display public key
        echo
        log_info "Your SSH public key (copy this to GitHub/GitLab):"
        echo "=========================================="
        cat "$ssh_key.pub"
        echo "=========================================="
        echo
    else
        log_info "SSH key already exists at $ssh_key"
    fi
}

create_gitignore_global() {
    log_step "Creating global gitignore"
    
    local gitignore_global="$HOME/.gitignore_global"
    
    cat > "$gitignore_global" << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Editor files
*~
*.swp
*.swo
.vscode/
.idea/
*.sublime-project
*.sublime-workspace

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Runtime data
pids
*.pid
*.seed
*.pid.lock

# Dependency directories
node_modules/
bower_components/

# Optional npm cache directory
.npm

# Optional REPL history
.node_repl_history

# Output of 'npm pack'
*.tgz

# Yarn Integrity file
.yarn-integrity

# dotenv environment variables file
.env

# Temporary folders
tmp/
temp/
.tmp/

# Build outputs
dist/
build/
out/

# IDE files
.vscode/
.idea/
*.iml
*.ipr
*.iws

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
env.bak/
venv.bak/
.pytest_cache/

# Virtual environments
.virtualenv

# Jupyter Notebook
.ipynb_checkpoints

# pyenv
.python-version

# Rust
target/
Cargo.lock

# Go
vendor/

# Java
*.class
*.jar
*.war
*.ear

# C/C++
*.o
*.so
*.dylib
*.exe

# Archives
*.zip
*.tar.gz
*.rar
*.7z
EOF

    git config --global core.excludesfile "$gitignore_global"
    
    log_success "Global gitignore created at $gitignore_global"
}

main() {
    log_info "Starting Git setup"
    
    # Check if Git is already installed
    if command -v git >/dev/null 2>&1; then
        log_info "Git is already installed"
    else
        install_git
    fi
    
    configure_git
    create_gitignore_global
    setup_ssh_key
    
    log_success "Git setup completed successfully"
    
    # Show Git version
    local git_version
    git_version=$(git --version)
    log_info "Installed: $git_version"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 