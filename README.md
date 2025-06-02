# 🚀 Universal Dotfiles & System Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Stars](https://img.shields.io/github/stars/matbrgz/dotfiles?style=social)](https://github.com/matbrgz/dotfiles)
[![Forks](https://img.shields.io/github/forks/matbrgz/dotfiles?style=social)](https://github.com/matbrgz/dotfiles)

```
    ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
    ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
    ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
    ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
    ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
    ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
                      by matbrgz
```

> **Universal system configuration tool for Linux distributions with intelligent package management and modern shell scripting practices.**

## ✨ Features

- 🎯 **Universal Compatibility**: Support for Debian/Ubuntu, Arch, Fedora, SUSE, and more
- 🔧 **Intelligent Package Management**: Auto-detects and uses apt, pacman, yay, dnf, zypper, snap, flatpak, brew
- 📦 **70+ Pre-configured Programs**: Essential tools, development environments, and desktop applications
- 🎨 **Beautiful UI**: Colored output with progress indicators
- ⚡ **Multi-Platform Support**: Linux, WSL, macOS, and Windows PowerShell scripts
- 🔒 **Backup System**: Automatic backup of existing configurations
- 🎛️ **Preset Configurations**: Quick setup for different use cases (minimal, webdev, fullstack, devops, desktop)
- 🔄 **JSON Configuration**: Centralized, validated settings with environment-specific overrides
- 📊 **Interactive Installation**: Choose programs and configurations interactively
- 🔍 **System Detection**: Automatic OS and package manager detection

## 📦 Available Programs

### 🔧 Essential Tools
- **git** - Distributed version control system
- **curl** - Command line tool for transferring data  
- **wget** - Command-line utility for downloading files
- **unzip** - Extraction utility for zip archives
- **htop** - Interactive process viewer
- **tmux** - Terminal multiplexer
- **vim** - Highly configurable text editor
- **ssh** - Secure Shell protocol suite

### 💻 Development Environment
- **nodejs** - JavaScript runtime built on Chrome's V8 engine
- **nvm** - Node Version Manager
- **python3** - High-level programming language
- **pyenv** - Python Version Manager
- **anaconda** - Python distribution for data science
- **golang** - Go programming language
- **rvm** - Ruby Version Manager
- **php** - Server-side scripting language
- **php-composer** - Dependency manager for PHP
- **php-laravel** - PHP web application framework
- **jdk** - Java Development Kit
- **dotnet** - .NET Core framework
- **vscode** - Visual Studio Code editor
- **insomnia** - REST API client

### 🐳 DevOps & Infrastructure
- **docker** - Containerization platform
- **kubectl** - Kubernetes command-line tool
- **kubernetes-helm** - Kubernetes package manager
- **terraform** - Infrastructure as Code tool
- **ansible** - IT automation platform
- **vagrant** - Development environment manager
- **azurecli** - Azure command-line interface
- **gcloudsdk** - Google Cloud SDK
- **powershell** - Cross-platform command-line shell

### 🌐 Web Development
- **apache** - HTTP web server
- **nginx** - HTTP and reverse proxy server
- **mysql** - Relational database management system
- **mongodb** - Document-based NoSQL database
- **redis** - In-memory data structure store
- **postgresql** - Advanced open-source relational database

### 🖥️ Desktop Applications
- **chrome** - Google Chrome web browser
- **firefox** - Mozilla Firefox web browser
- **discord** - Voice, video and text communication
- **spotify** - Digital music streaming service
- **vlc** - Cross-platform multimedia player
- **steam** - Digital game distribution platform
- **qbittorrent** - BitTorrent client
- **bitwarden** - Password manager

### ☁️ Cloud Storage
- **dropbox** - Cloud storage service
- **megasync** - MEGA cloud storage client

### 🛠️ System Utilities
- **shellcheck** - Static analysis tool for shell scripts
- **shfmt** - Shell script formatter
- **mosh** - Mobile shell with roaming
- **x11server** - X Window System server
- **protobuf** - Language-neutral data serialization
- **netkit** - Network emulation toolkit

### 🎨 Media & Entertainment
- **vlc** - VLC Media Player
- **spotify** - Music streaming
- **steam** - Gaming platform

### 📱 Productivity Tools
- **station** - Smart browser for busy people
- **sharex** - Screen capture and file sharing
- **httrack** - Website copier
- **ccleaner** - System optimization

## 🚀 Quick Start

### Express Installation (Recommended)
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

### WSL Installation
```bash
git clone https://github.com/matbrgz/dotfiles.git
cd dotfiles
bash install.sh --wsl
```

## 📖 Installation Modes

### 🎯 Express Mode
Installs essential tools with smart defaults:
```bash
./install.sh --express
```

### 🎨 Interactive Mode
Choose programs and configurations:
```bash
./install.sh --interactive
```

### 📋 Preset Mode
Quick setup for specific use cases:
```bash
./install.sh --preset webdev     # Web development
./install.sh --preset fullstack  # Full stack development
./install.sh --preset devops     # DevOps engineer
./install.sh --preset desktop    # Desktop user
./install.sh --preset minimal    # Essential tools only
```

### ⚙️ Configuration Only
Apply configs without installing programs:
```bash
./install.sh --config-only
```

## 🔧 Configuration

### Settings File
The main configuration is in `bootstrap/settings.json`:

```json
{
  "personal": {
    "name": "matbrgz",
    "email": "matbrgz@gmail.com",
    "githubuser": "matbrgz",
    "defaultfolder": {
      "linux": "~/dev",
      "wsl": "~/dev", 
      "windows": "~/dev"
    }
  },
  "system": {
    "detection": {
      "auto_detect_os": true,
      "auto_detect_package_manager": true
    },
    "behavior": {
      "debug_mode": false,
      "backup_configs": true,
      "parallel_installs": true
    }
  }
}
```

### Environment Variables
```bash
export DOTFILES_CONFIG_PATH="./bootstrap/settings.json"
export DOTFILES_INSTALL_MODE="interactive"
export DOTFILES_BACKUP_DIR="$HOME/.dotfiles-backup"
export DOTFILES_LOG_LEVEL="info"
```

## 🎛️ Advanced Usage

### Custom Configuration
```bash
./install.sh --config /path/to/custom-settings.json
```

### Specific Programs
```bash
./install.sh --programs "git,docker,nodejs,vscode"
```

### Force Reinstall
```bash
./install.sh --force
```

### Debug Mode
```bash
./install.sh --debug
```

### Dry Run
```bash
./install.sh --dry-run
```

## 🔄 Package Manager Support

| Distribution | Primary | Secondary | Tertiary |
|-------------|---------|-----------|----------|
| **Ubuntu/Debian** | apt | snap | flatpak |
| **Arch Linux** | pacman | yay | - |
| **Fedora** | dnf | snap | flatpak |
| **openSUSE** | zypper | snap | flatpak |
| **macOS** | brew | - | - |
| **Windows** | choco | - | - |

## 📁 Directory Structure

```
dotfiles/
├── 📁 bootstrap/           # Configuration files
│   ├── settings.json       # Main configuration
│   └── version.json       # Software versions
├── 📁 lib/                # Utility libraries  
│   └── utils.sh           # Common functions
├── 📁 programs/           # Installation scripts
│   ├── configs/           # Configuration files
│   └── *.sh              # Program installers
├── 📁 configurations/     # System configurations
│   └── git/              # Git specific configs
├── 📁 commands/           # Custom commands
├── 📁 scaffolding/        # Project templates
└── install.sh            # Main installer
```

## 🎨 Customization

### Personal Settings
Edit your personal information in `bootstrap/settings.json`:

```json
{
  "personal": {
    "name": "Your Name",
    "email": "your.email@example.com", 
    "githubuser": "yourusername"
  }
}
```

### Program Categories
Programs are organized into categories. You can enable/disable entire categories:

```json
{
  "categories": {
    "development": {
      "enabled": true,
      "programs": ["nodejs", "python3", "golang", "docker"]
    }
  }
}
```

### Custom Presets
Create your own installation presets:

```json
{
  "presets": {
    "mysetup": {
      "name": "My Custom Setup",
      "description": "My personal development environment",
      "programs": ["git", "nodejs", "docker", "vscode"]
    }
  }
}
```

## 🔍 System Information

The installer automatically detects:
- **Operating System**: Linux distributions, macOS, Windows (WSL)
- **Package Managers**: apt, pacman, yay, dnf, zypper, snap, flatpak, brew, choco
- **Architecture**: x86_64, arm64, i386
- **Environment**: Desktop, Server, WSL, Docker

## 🧪 Testing

Run the test suite:
```bash
./scripts/test.sh
```

Validate configuration:
```bash
./scripts/validate-config.sh
```

## 🤝 Contributing

We welcome contributions! See our [Contributing Guide](CONTRIBUTING.md) for details.

### Quick Contribution Steps
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Adding New Programs
1. Create script in `programs/`
2. Add configuration to `bootstrap/settings.json`
3. Update documentation
4. Test across different systems

## 📋 Requirements

### Minimum Requirements
- **OS**: Linux (any distribution), macOS 10.15+, Windows 10+ (WSL)
- **Memory**: 512MB RAM
- **Storage**: 1GB free space
- **Network**: Internet connection for downloads

### Recommended
- **Memory**: 2GB+ RAM
- **Storage**: 5GB+ free space
- **Terminal**: Modern terminal with color support

## 🔧 Troubleshooting

### Common Issues

**Permission Denied**
```bash
chmod +x install.sh
sudo ./install.sh
```

**Package Manager Not Found**
```bash
./install.sh --force-package-manager apt
```

**Network Issues**
```bash
./install.sh --offline --local-packages
```

**WSL Issues**
```bash
./install.sh --wsl --fix-permissions
```

### Debug Mode
Enable detailed logging:
```bash
export DOTFILES_DEBUG=1
./install.sh --debug
```

### Reset Installation
```bash
./scripts/reset.sh
```

## 📊 Statistics

- **70+ Programs** supported
- **9 Package Managers** supported  
- **15+ Linux Distributions** tested
- **4 Installation Modes**
- **7 Preset Configurations**
- **Multi-platform Support**

## 🙏 Acknowledgments

- [Dotbot](https://github.com/anishathalye/dotbot) - Inspiration for configuration management
- [Homebrew](https://brew.sh/) - Package management inspiration
- [Oh My Zsh](https://ohmyz.sh/) - Shell configuration ideas
- Community contributors and testers

## 📞 Support

- 🐛 [Issues](https://github.com/matbrgz/dotfiles/issues)
- 💬 [Discussions](https://github.com/matbrgz/dotfiles/discussions)  
- 📧 [Email](mailto:matbrgz@gmail.com)
- 🐦 [Twitter](https://twitter.com/matbrgz)

## 📜 License

This project is licensed under the [MIT License](LICENSE) - see the LICENSE file for details.

---

**⭐ Star this repository if it helped you!** 

Made with ❤️ by [matbrgz](https://github.com/matbrgz)

