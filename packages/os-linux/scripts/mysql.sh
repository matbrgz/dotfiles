#!/bin/bash

# =============================================================================
# MYSQL SERVER INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure MySQL database server
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_mysql() {
	log_step "Installing MySQL Server"
	
	local pm
	pm=$(detect_package_manager)
	
	# Get MySQL version from version.json
	local mysql_version
	mysql_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".mysql")
	
	if [[ "$mysql_version" == "null" ]]; then
		log_warning "MySQL version not found in version.json, using 8.0"
		mysql_version="8.0"
	fi
	
	# Extract major.minor version (e.g., "9.1.0" -> "8.0")
	local mysql_major_minor
	mysql_major_minor=$(echo "$mysql_version" | cut -d'.' -f1-2)
	
	log_info "Installing MySQL $mysql_major_minor"
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing MySQL installation"
		case "$pm" in
			"apt")
				sudo systemctl stop mysql 2>/dev/null || true
				sudo apt remove -y mysql-server mysql-client mysql-common 2>/dev/null || true
				sudo apt purge -y mysql-server mysql-client mysql-common 2>/dev/null || true
				sudo apt autoremove -y
				sudo rm -rf /var/lib/mysql 2>/dev/null || true
				sudo rm -rf /etc/mysql 2>/dev/null || true
				;;
			"pacman"|"yay")
				sudo systemctl stop mysqld 2>/dev/null || true
				sudo pacman -Rs --noconfirm mysql 2>/dev/null || true
				;;
			"dnf")
				sudo systemctl stop mysqld 2>/dev/null || true
				sudo dnf remove -y mysql-server mysql 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install MySQL
	case "$pm" in
		"apt")
			install_mysql_apt "$mysql_major_minor"
			;;
		"pacman")
			sudo pacman -S --noconfirm mysql
			;;
		"yay")
			yay -S --noconfirm mysql
			;;
		"dnf")
			sudo dnf install -y mysql-server mysql
			;;
		"zypper")
			sudo zypper install -y mysql mysql-server
			;;
		"brew")
			brew install mysql
			;;
		*)
			log_error "Unsupported package manager: $pm"
			return 1
			;;
	esac
	
	log_success "MySQL installed successfully"
}

install_mysql_apt() {
	local mysql_version="$1"
	
	log_step "Installing MySQL via APT"
	
	# Pre-configure MySQL to avoid interactive prompts
	local mysql_root_password="root"
	
	# Set MySQL root password
	echo "mysql-server mysql-server/root_password password $mysql_root_password" | sudo debconf-set-selections
	echo "mysql-server mysql-server/root_password_again password $mysql_root_password" | sudo debconf-set-selections
	
	# Update package list
	sudo apt update
	
	# Install MySQL
	sudo DEBIAN_FRONTEND=noninteractive apt install -y \
		mysql-server \
		mysql-client \
		mysql-common \
		libmysqlclient-dev
	
	log_success "MySQL installed via APT"
}

configure_mysql() {
	log_step "Configuring MySQL"
	
	# Start MySQL service
	if command -v systemctl >/dev/null 2>&1; then
		sudo systemctl enable mysql 2>/dev/null || sudo systemctl enable mysqld 2>/dev/null || true
		sudo systemctl start mysql 2>/dev/null || sudo systemctl start mysqld 2>/dev/null || true
		log_success "MySQL service started and enabled"
	else
		# Fallback for systems without systemctl
		sudo service mysql start 2>/dev/null || sudo service mysqld start 2>/dev/null || true
		log_success "MySQL service started"
	fi
	
	# Wait for MySQL to be ready
	log_step "Waiting for MySQL to be ready"
	local max_attempts=30
	local attempt=1
	
	while [[ $attempt -le $max_attempts ]]; do
		if mysqladmin ping -u root --password=root >/dev/null 2>&1; then
			log_success "MySQL is ready"
			break
		fi
		
		if [[ $attempt -eq $max_attempts ]]; then
			log_warning "MySQL may not be fully ready, continuing..."
			break
		fi
		
		log_info "Attempt $attempt/$max_attempts - waiting for MySQL..."
		sleep 2
		((attempt++))
	done
	
	# Configure MySQL for remote access
	configure_mysql_remote_access
	
	# Create development user
	create_development_user
	
	# Configure MySQL settings
	configure_mysql_settings
}

configure_mysql_remote_access() {
	log_step "Configuring MySQL for remote access"
	
	local mysql_config="/etc/mysql/mysql.conf.d/mysqld.cnf"
	local mysql_config_alt="/etc/mysql/my.cnf"
	
	# Find MySQL config file
	local config_file=""
	if [[ -f "$mysql_config" ]]; then
		config_file="$mysql_config"
	elif [[ -f "$mysql_config_alt" ]]; then
		config_file="$mysql_config_alt"
	else
		log_warning "MySQL config file not found, skipping remote access configuration"
		return
	fi
	
	# Backup original config
	sudo cp "$config_file" "$config_file.backup.$(date +%Y%m%d_%H%M%S)"
	
	# Allow remote connections
	sudo sed -i 's/bind-address.*=.*/bind-address = 0.0.0.0/' "$config_file"
	
	log_success "MySQL configured for remote access"
}

create_development_user() {
	log_step "Creating development user"
	
	# Create a development user with full privileges
	local dev_user="dev"
	local dev_password="dev123"
	
	mysql -u root --password=root -e "
		CREATE USER IF NOT EXISTS '${dev_user}'@'localhost' IDENTIFIED BY '${dev_password}';
		GRANT ALL PRIVILEGES ON *.* TO '${dev_user}'@'localhost' WITH GRANT OPTION;
		CREATE USER IF NOT EXISTS '${dev_user}'@'%' IDENTIFIED BY '${dev_password}';
		GRANT ALL PRIVILEGES ON *.* TO '${dev_user}'@'%' WITH GRANT OPTION;
		FLUSH PRIVILEGES;
	" 2>/dev/null || log_warning "Failed to create development user"
	
	log_success "Development user created: $dev_user / $dev_password"
}

configure_mysql_settings() {
	log_step "Configuring MySQL settings"
	
	# Run mysql_secure_installation equivalent
	mysql -u root --password=root -e "
		DELETE FROM mysql.user WHERE User='';
		DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
		DROP DATABASE IF EXISTS test;
		DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
		FLUSH PRIVILEGES;
	" 2>/dev/null || log_warning "Failed to run security configuration"
	
	log_success "MySQL security settings applied"
}

create_mysql_aliases() {
	log_step "Creating MySQL aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# MySQL aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "MySQL aliases already exist in $bashrc"
		return 0
	fi
	
	# Add MySQL aliases
	cat >> "$bashrc" << 'EOF'

# MySQL aliases added by matbrgz dotfiles
alias mysql-root='mysql -u root -p'
alias mysql-dev='mysql -u dev -p'
alias mysql-status='sudo systemctl status mysql'
alias mysql-start='sudo systemctl start mysql'
alias mysql-stop='sudo systemctl stop mysql'
alias mysql-restart='sudo systemctl restart mysql'
alias mysql-logs='sudo journalctl -u mysql -f'
alias mysql-config='sudo nano /etc/mysql/mysql.conf.d/mysqld.cnf'

# MySQL helpers
alias mysql-show-dbs='mysql -u root -p -e "SHOW DATABASES;"'
alias mysql-show-users='mysql -u root -p -e "SELECT User, Host FROM mysql.user;"'
alias mysql-processlist='mysql -u root -p -e "SHOW PROCESSLIST;"'
alias mysql-variables='mysql -u root -p -e "SHOW VARIABLES;"'
alias mysql-backup='mysqldump -u root -p --all-databases'
EOF
	
	log_success "MySQL aliases added to $bashrc"
}

install_mysql_tools() {
	log_step "Installing MySQL tools"
	
	local pm
	pm=$(detect_package_manager)
	
	case "$pm" in
		"apt")
			sudo apt install -y mysql-workbench 2>/dev/null || log_info "MySQL Workbench not available in repositories"
			;;
		"pacman")
			sudo pacman -S --noconfirm mysql-workbench 2>/dev/null || log_info "MySQL Workbench not available"
			;;
		"brew")
			brew install --cask mysql-workbench 2>/dev/null || log_info "MySQL Workbench not available"
			;;
		*)
			log_info "MySQL Workbench installation not configured for $pm"
			;;
	esac
}

verify_installation() {
	log_step "Verifying MySQL installation"
	
	# Check if MySQL service is running
	if systemctl is-active --quiet mysql 2>/dev/null || systemctl is-active --quiet mysqld 2>/dev/null; then
		log_success "MySQL service is running"
	else
		log_warning "MySQL service status unclear"
	fi
	
	# Check MySQL version
	if command -v mysql >/dev/null 2>&1; then
		local version
		version=$(mysql --version)
		log_success "MySQL version: $version"
		
		# Test connection
		if mysql -u root --password=root -e "SELECT 1;" >/dev/null 2>&1; then
			log_success "MySQL root connection successful"
		else
			log_warning "MySQL root connection failed"
		fi
		
		# Test development user
		if mysql -u dev --password=dev123 -e "SELECT 1;" >/dev/null 2>&1; then
			log_success "MySQL development user connection successful"
		else
			log_warning "MySQL development user connection failed"
		fi
		
	else
		log_error "MySQL client not found"
		return 1
	fi
}

show_usage() {
	echo
	log_info "MySQL usage:"
	echo "  - Connect as root: mysql-root"
	echo "  - Connect as dev: mysql-dev"
	echo "  - Service control: mysql-start, mysql-stop, mysql-restart"
	echo "  - View logs: mysql-logs"
	echo "  - Edit config: mysql-config"
	echo "  - Show databases: mysql-show-dbs"
	echo "  - Show users: mysql-show-users"
	echo
	log_info "Default credentials:"
	echo "  - Root user: root / root"
	echo "  - Dev user: dev / dev123"
	echo
	log_info "Configuration:"
	echo "  - Config file: /etc/mysql/mysql.conf.d/mysqld.cnf"
	echo "  - Data directory: /var/lib/mysql"
	echo "  - Default port: 3306"
	echo "  - Remote access: enabled (bind-address: 0.0.0.0)"
	echo
	log_info "Security recommendations:"
	echo "  - Change default passwords"
	echo "  - Limit remote access if not needed"
	echo "  - Regular backups: mysql-backup > backup.sql"
}

main() {
	log_info "Starting MySQL setup"
	
	install_mysql
	configure_mysql
	create_mysql_aliases
	install_mysql_tools
	verify_installation
	show_usage
	
	log_success "MySQL setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
