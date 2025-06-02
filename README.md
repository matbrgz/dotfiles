# 🚀 Universal Dotfiles & System Setup

**Author:** matbrgz  
**Version:** 2.0  
**License:** MIT

A modern, universal dotfiles and system setup tool that works across multiple Linux distributions with automatic package manager detection and intelligent configuration management.

## ✨ Features

- 🔍 **Automatic Detection**: Detects your OS, distribution, and package manager automatically
- 📦 **Multi-Package Manager Support**: Works with `apt`, `pacman`, `yay`, `dnf`, `zypper`, `snap`, `flatpak`, and `brew`
- 🎯 **Preset Configurations**: Choose from predefined setups (minimal, webdev, fullstack, devops, desktop)
- 🛠️ **Modular Design**: Each program has its own installation and configuration script
- 📋 **Interactive Installation**: Choose exactly what you want to install
- 🔧 **Smart Configuration**: Automatically configures installed programs with sensible defaults
- 📝 **Comprehensive Logging**: Full installation logs with timestamps
- 🔄 **Backup System**: Automatically backs up existing configurations
- 🎨 **Beautiful UI**: Colored output with progress indicators

## 🖥️ Supported Systems

### Operating Systems
- Ubuntu (18.04+)
- Debian (10+)
- Arch Linux
- Manjaro
- Fedora (32+)
- CentOS/RHEL (8+)
- openSUSE
- WSL (Windows Subsystem for Linux)

### Package Managers
- **APT** (Ubuntu, Debian)
- **Pacman** (Arch Linux)
- **YAY** (AUR helper for Arch)
- **DNF** (Fedora, CentOS)
- **Zypper** (openSUSE)
- **Snap** (Universal packages)
- **Flatpak** (Universal packages)
- **Homebrew** (macOS, Linux)

## 🚀 Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/matbrgz/dotfiles/main/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/matbrgz/dotfiles.git
cd dotfiles
chmod +x install.sh
./install.sh
```

## 📋 Installation Types

### 1. Express Install
Installs essential tools with default settings - perfect for quick setup.

### 2. Custom Install
Choose specific program categories to install:
- **Essential Tools**: git, curl, wget, unzip, htop, tmux, vim
- **Development Environment**: nodejs, python3, golang, docker, vscode
- **Web Development**: apache, nginx, php, mysql, mongodb
- **DevOps Tools**: docker, kubectl, terraform, ansible, vagrant
- **Desktop Applications**: chrome, firefox, vscode, discord, spotify

### 3. Preset Install
Choose from predefined configurations:
- **Minimal**: Only essential tools
- **Web Development**: Full web development stack
- **Full Stack Developer**: Complete development environment
- **DevOps Engineer**: Infrastructure and deployment tools
- **Desktop User**: Desktop applications and productivity tools

### 4. Configuration Only
Only configure already installed programs without installing new ones.

## ⚙️ Configuration

### Personal Settings

Edit `settings.json` to customize your installation:

```json
{
  "personal": {
    "name": "Your Name",
    "email": "your.email@example.com",
    "githubuser": "yourusername",
    "defaultfolder": {
      "linux": "~/Dev",
      "wsl": "/mnt/c/Dev",
      "windows": "C:\\Dev"
    }
  }
}
```

### System Behavior

```json
{
  "system": {
    "behavior": {
      "debug_mode": false,
      "purge_mode": false,
      "parallel_installs": true,
      "continue_on_error": false,
      "backup_configs": true
    }
  }
}
```

## 📦 Supported Programs

<details>
<summary>Click to expand the full list</summary>

### Essential Tools
- Git (with LFS support)
- cURL & Wget
- Unzip & compression tools
- htop (process viewer)
- tmux (terminal multiplexer)
- Vim (text editor)

### Development Languages
- Node.js (with npm)
- Python 3 (with pip)
- Go (Golang)
- PHP (with extensions)

### Development Tools
- Visual Studio Code
- Docker & Docker Compose
- Git (with advanced configuration)

### Web Servers & Databases
- Apache HTTP Server
- Nginx
- MySQL
- MongoDB
- PostgreSQL (planned)

### DevOps & Infrastructure
- Docker & Docker Compose
- Kubernetes (kubectl)
- Terraform
- Ansible
- Vagrant

### Desktop Applications
- Google Chrome
- Mozilla Firefox
- Discord
- Spotify

</details>

## 🛠️ Advanced Usage

### Running Individual Scripts

```bash
# Install and configure Git
./programs/git.sh

# Install Docker
./programs/docker.sh

# Just configure an already installed program
./programs/configs/git-config.sh
```

### Using Different Package Managers

The script automatically detects your package manager, but you can check what it detects:

```bash
./lib/utils.sh  # Shows system information
```

### Debug Mode

Enable debug mode for troubleshooting:

```bash
# Set in settings.json
"debug_mode": true

# Or export environment variable
export DEBUG_MODE=true
./install.sh
```

## 📁 Project Structure

```
dotfiles/
├── install.sh              # Main installation script
├── settings.json            # Configuration file
├── lib/
│   └── utils.sh            # Utility functions
├── programs/
│   ├── git.sh              # Git installation
│   ├── docker.sh           # Docker installation
│   ├── nodejs.sh           # Node.js installation
│   └── configs/            # Configuration-only scripts
│       ├── git-config.sh
│       └── docker-config.sh
├── logs/                   # Installation logs
├── backups/                # Configuration backups
└── README.md               # This file
```

## 🔧 Customization

### Adding New Programs

1. Create a new script in `programs/`
2. Add the program definition to `settings.json`
3. Follow the existing script structure

### Example Program Script

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$PROJECT_ROOT/lib/utils.sh"

main() {
    log_info "Installing My Program"
    
    local pm
    pm=$(detect_package_manager)
    
    install_package "$pm" "my-program"
    
    log_success "My Program installed successfully"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Development Setup

```bash
git clone https://github.com/matbrgz/dotfiles.git
cd dotfiles
# Make your changes
./install.sh  # Test your changes
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by the dotfiles community
- Built with modern shell scripting best practices
- Designed to help developers quickly set up new systems

## 📞 Support

If you encounter any issues or have questions:

1. Check the [logs/] directory for detailed error information
2. Open an issue on GitHub
3. Make sure your system is supported

## 🗺️ Roadmap

- [ ] PowerShell version for Windows
- [ ] macOS native support (without Homebrew dependency)
- [ ] GUI installer
- [ ] Cloud synchronization of settings
- [ ] Plugin system for community extensions
- [ ] Ansible playbook generation
- [ ] Docker containerized installer

---

**Made with ❤️ by matbrgz**

*"One script to rule them all, one script to configure them all!"*

