#!/bin/bash

# PHP Development Environment Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="PHP Development Environment"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_php_version() {
	php_version=$(get_json_value "php")
	if [[ -z "$php_version" || "$php_version" == "null" ]]; then
		php_version="8.4.2"
	fi
	echo "$php_version"
}

get_apache_version() {
	apache_version=$(get_json_value "apache")
	if [[ -z "$apache_version" || "$apache_version" == "null" ]]; then
		apache_version="2.4.62"
	fi
	echo "$apache_version"
}

get_composer_version() {
	composer_version=$(get_json_value "composer")
	if [[ -z "$composer_version" || "$composer_version" == "null" ]]; then
		composer_version="2.8.5"
	fi
	echo "$composer_version"
}

# Check if PHP is already installed
check_php_installation() {
	if command -v php >/dev/null 2>&1; then
		local current_version
		current_version=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1-2)
		log_warning "PHP is already installed (version $current_version)"
		return 0
	fi
	return 1
}

# Install PHP and extensions
install_php() {
	log_step "Installing PHP"
	
	local php_version apache_version
	php_version=$(get_php_version)
	apache_version=$(get_apache_version)
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Add Ondrej's PHP repository for latest versions
			sudo apt-get update
			sudo apt-get install -y software-properties-common
			sudo add-apt-repository -y ppa:ondrej/php
			sudo apt-get update
			
			# Install PHP and essential extensions
			sudo apt-get install -y \
				"php${php_version}" \
				"php${php_version}-cli" \
				"php${php_version}-common" \
				"php${php_version}-curl" \
				"php${php_version}-gd" \
				"php${php_version}-mbstring" \
				"php${php_version}-mysql" \
				"php${php_version}-xml" \
				"php${php_version}-zip" \
				"php${php_version}-json" \
				"php${php_version}-pdo" \
				"php${php_version}-dev" \
				"php${php_version}-bcmath" \
				"php${php_version}-intl" \
				"php${php_version}-soap" \
				"php${php_version}-sqlite3" \
				"php${php_version}-opcache" \
				"php${php_version}-readline" \
				"php${php_version}-xdebug"
			;;
		yay|pacman)
			sudo pacman -S --needed --noconfirm php php-apache php-cgi \
				php-fpm php-gd php-sqlite php-intl php-mcrypt \
				php-snmp php-pgsql php-odbc php-phpdbg php-embed \
				php-enchant php-imap php-xsl
			;;
		dnf)
			sudo dnf install -y php php-cli php-common php-gd php-mbstring \
				php-mysql php-xml php-zip php-json php-pdo php-dev \
				php-curl php-opcache php-intl php-bcmath php-soap
			;;
		zypper)
			sudo zypper install -y php8 php8-cli php8-gd php8-mbstring \
				php8-mysql php8-xml php8-zip php8-json php8-pdo \
				php8-curl php8-opcache php8-intl php8-bcmath
			;;
		brew)
			brew install php
			;;
		*)
			log_error "Package manager not supported for PHP installation"
			return 1
			;;
	esac
	
	log_success "PHP installed successfully"
}

# Install Composer
install_composer() {
	log_step "Installing Composer"
	
	if command -v composer >/dev/null 2>&1; then
		log_warning "Composer is already installed"
		composer --version
		return 0
	fi
	
	# Download and install Composer
	local composer_installer="/tmp/composer-setup.php"
	local composer_hash
	
	# Get expected hash
	composer_hash=$(curl -sS https://composer.github.io/installer.sig)
	
	# Download installer
	curl -sS https://getcomposer.org/installer -o "$composer_installer"
	
	# Verify installer
	if php -r "if (hash_file('sha384', '$composer_installer') === '$composer_hash') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('$composer_installer'); exit(1); }"; then
		log_success "Composer installer verified"
	else
		log_error "Composer installer verification failed"
		return 1
	fi
	
	# Install Composer globally
	sudo php "$composer_installer" --install-dir=/usr/local/bin --filename=composer
	rm "$composer_installer"
	
	# Verify installation
	if command -v composer >/dev/null 2>&1; then
		log_success "Composer installed successfully"
		composer --version
	else
		log_error "Composer installation failed"
		return 1
	fi
}

# Configure PHP
configure_php() {
	log_step "Configuring PHP"
	
	local php_version
	php_version=$(get_php_version)
	local php_ini_path
	
	# Find PHP configuration file
	if [[ -f "/etc/php/${php_version}/cli/php.ini" ]]; then
		php_ini_path="/etc/php/${php_version}/cli/php.ini"
	elif [[ -f "/etc/php.ini" ]]; then
		php_ini_path="/etc/php.ini"
	else
		php_ini_path=$(php --ini | grep "Loaded Configuration File" | cut -d':' -f2 | xargs)
	fi
	
	if [[ -n "$php_ini_path" && -f "$php_ini_path" ]]; then
		# Create backup
		sudo cp "$php_ini_path" "${php_ini_path}.backup.$(date +%Y%m%d_%H%M%S)"
		
		# Configure PHP settings for development
		sudo tee -a "$php_ini_path" > /dev/null << 'EOF'

; Custom PHP Configuration for Development
memory_limit = 512M
post_max_size = 100M
upload_max_filesize = 100M
max_execution_time = 300
max_input_vars = 3000
display_errors = On
display_startup_errors = On
log_errors = On
error_reporting = E_ALL
date.timezone = "UTC"
EOF
		
		log_success "PHP configuration updated"
	fi
}

# Create development environment
create_dev_environment() {
	log_step "Creating PHP development environment"
	
	local webroot="$HOME/php-projects"
	
	# Create web projects directory
	mkdir -p "$webroot"
	
	# Create a sample PHP project
	local sample_project="$webroot/sample-app"
	if [[ ! -d "$sample_project" ]]; then
		mkdir -p "$sample_project"
		cd "$sample_project"
		
		# Create composer.json
		cat > composer.json << 'EOF'
{
    "name": "sample/php-app",
    "description": "Sample PHP application",
    "type": "project",
    "require": {
        "php": ">=8.1",
        "guzzlehttp/guzzle": "^7.0",
        "monolog/monolog": "^3.0",
        "vlucas/phpdotenv": "^5.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^10.0",
        "squizlabs/php_codesniffer": "^3.0",
        "phpstan/phpstan": "^1.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "src/"
        }
    },
    "scripts": {
        "test": "phpunit",
        "lint": "phpcs --standard=PSR12 src/",
        "analyze": "phpstan analyse src/",
        "fix": "phpcbf --standard=PSR12 src/"
    }
}
EOF
		
		# Create directory structure
		mkdir -p src public tests config
		
		# Create sample application
		cat > src/App.php << 'EOF'
<?php

namespace App;

use GuzzleHttp\Client;
use Monolog\Logger;
use Monolog\Handler\StreamHandler;

class App
{
    private Logger $logger;
    private Client $httpClient;

    public function __construct()
    {
        $this->logger = new Logger('app');
        $this->logger->pushHandler(new StreamHandler('php://stdout', Logger::DEBUG));
        $this->httpClient = new Client();
    }

    public function run(): void
    {
        $this->logger->info('Starting PHP Sample Application');
        
        try {
            $response = $this->httpClient->get('https://api.github.com/users/octocat');
            $data = json_decode($response->getBody()->getContents(), true);
            
            $this->logger->info('User data retrieved', [
                'name' => $data['name'] ?? 'N/A',
                'repos' => $data['public_repos'] ?? 0,
                'followers' => $data['followers'] ?? 0
            ]);
            
            echo "GitHub User: " . ($data['name'] ?? $data['login']) . "\n";
            echo "Public Repos: " . ($data['public_repos'] ?? 0) . "\n";
            echo "Followers: " . ($data['followers'] ?? 0) . "\n";
            
        } catch (\Exception $e) {
            $this->logger->error('Error occurred', ['exception' => $e->getMessage()]);
            echo "Error: " . $e->getMessage() . "\n";
        }
    }
}
EOF
		
		# Create public index
		cat > public/index.php << 'EOF'
<?php

require_once __DIR__ . '/../vendor/autoload.php';

use App\App;

$app = new App();
$app->run();
EOF
		
		# Create CLI runner
		cat > app.php << 'EOF'
#!/usr/bin/env php
<?php

require_once __DIR__ . '/vendor/autoload.php';

use App\App;

$app = new App();
$app->run();
EOF
		
		# Create test file
		cat > tests/AppTest.php << 'EOF'
<?php

use PHPUnit\Framework\TestCase;
use App\App;

class AppTest extends TestCase
{
    public function testAppCanBeInstantiated(): void
    {
        $app = new App();
        $this->assertInstanceOf(App::class, $app);
    }
}
EOF
		
		# Create README
		cat > README.md << 'EOF'
# PHP Sample Application

A sample PHP application demonstrating modern PHP development practices.

## Setup

```bash
composer install
```

## Usage

```bash
# Run via CLI
php app.php

# Run via web server
php -S localhost:8000 -t public/
# Then visit: http://localhost:8000
```

## Development

```bash
# Run tests
composer test

# Check code style
composer lint

# Fix code style
composer fix

# Static analysis
composer analyze
```

## Requirements

- PHP 8.1+
- Composer
EOF
		
		chmod +x app.php
		log_success "Sample PHP project created at $sample_project"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating PHP aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for PHP
	local php_aliases="
# PHP Aliases
alias php-version='php --version'
alias php-info='php --info'
alias php-modules='php -m'
alias php-config='php --ini'
alias php-serve='php -S localhost:8000'
alias php-serve-public='php -S localhost:8000 -t public/'
alias composer-install='composer install'
alias composer-update='composer update'
alias composer-require='composer require'
alias composer-dump='composer dump-autoload'
alias composer-outdated='composer outdated'
alias phpunit='./vendor/bin/phpunit'
alias phpcs='./vendor/bin/phpcs'
alias phpcbf='./vendor/bin/phpcbf'
alias phpstan='./vendor/bin/phpstan'
alias php-lint='find . -name \"*.php\" -exec php -l {} \;'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "PHP Aliases" "$alias_file"; then
			echo "$php_aliases" >> "$alias_file"
		fi
	else
		echo "$php_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "PHP aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying PHP installation"
	
	if command -v php >/dev/null 2>&1; then
		log_success "PHP installed successfully!"
		echo "  Version: $(php -v | head -n1)"
		echo "  Configuration: $(php --ini | grep "Loaded Configuration File" | cut -d':' -f2 | xargs)"
		
		if command -v composer >/dev/null 2>&1; then
			echo "  Composer: $(composer --version --no-ansi | head -n1)"
		fi
		
		echo "  Available extensions: $(php -m | wc -l) modules loaded"
		return 0
	else
		log_error "PHP installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

PHP Development Environment Usage:
=================================

Basic Commands:
  php -v                      Check PHP version
  php -m                      List installed modules
  php -S localhost:8000       Start development server
  php file.php               Execute PHP script

Composer Commands:
  composer init               Initialize new project
  composer install            Install dependencies
  composer require package    Add new dependency
  composer update             Update dependencies
  composer dump-autoload      Regenerate autoloader

Development Server:
  php -S localhost:8000                    Basic server
  php -S localhost:8000 -t public/        Server with document root
  php -S 0.0.0.0:8000                     Server accessible from network

Useful Aliases:
  php-serve                   Start development server
  php-serve-public            Start server with public/ as root
  composer-install            Install composer dependencies
  phpunit                     Run tests
  php-lint                    Check syntax of all PHP files

Configuration Files:
  /etc/php/*/cli/php.ini      PHP CLI configuration
  /etc/php/*/apache2/php.ini  PHP Apache configuration
  composer.json               Project dependencies
  .env                        Environment variables

For more information: https://www.php.net/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_php_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install PHP and tools
	install_php
	install_composer
	configure_php
	
	# Setup development environment
	create_dev_environment
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
