#!/bin/bash

# =============================================================================
# NGINX INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install and configure Nginx web server
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_nginx() {
	log_step "Installing Nginx"
	
	local pm
	pm=$(detect_package_manager)
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Nginx installation"
		case "$pm" in
			"apt")
				sudo apt remove -y nginx nginx-common nginx-core 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm nginx 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y nginx 2>/dev/null || true
				;;
			*)
				log_warning "Purge not implemented for package manager: $pm"
				;;
		esac
	fi
	
	# Install Nginx
	case "$pm" in
		"apt")
			sudo apt update
			sudo apt install -y nginx
			;;
		"pacman")
			sudo pacman -S --noconfirm nginx
			;;
		"yay")
			yay -S --noconfirm nginx
			;;
		"dnf")
			sudo dnf install -y nginx
			;;
		"zypper")
			sudo zypper install -y nginx
			;;
		"snap")
			sudo snap install nginx
			;;
		"brew")
			brew install nginx
			;;
		*)
			log_error "Unsupported package manager: $pm"
			return 1
			;;
	esac
	
	log_success "Nginx installed successfully"
}

configure_nginx() {
	log_step "Configuring Nginx"
	
	# Get default folder from settings
	local default_folder
	local os_type
	os_type=$(detect_os)
	default_folder=$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".personal.defaultfolder.$os_type")
	
	if [[ "$default_folder" == "null" ]]; then
		default_folder="$HOME/dev"
		log_warning "Default folder not set in settings, using: $default_folder"
	fi
	
	# Expand tilde to full path
	default_folder="${default_folder/#\~/$HOME}"
	
	# Create default folder if it doesn't exist
	if [[ ! -d "$default_folder" ]]; then
		mkdir -p "$default_folder"
		log_info "Created default folder: $default_folder"
	fi
	
	# Create a simple index.html
	cat > "$default_folder/index.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to Nginx!</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        .container { max-width: 600px; margin: 0 auto; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 Nginx is working!</h1>
        <p>This is a custom development server configured by matbrgz dotfiles.</p>
        <p>Document root: <code>DEFAULT_FOLDER</code></p>
    </div>
</body>
</html>
EOF
	
	# Replace placeholder with actual path
	sed -i "s|DEFAULT_FOLDER|$default_folder|g" "$default_folder/index.html"
	
	# Create custom Nginx config
	local nginx_config="/etc/nginx/sites-available/development"
	
	if [[ -d "/etc/nginx/sites-available" ]]; then
		log_step "Creating development site configuration"
		
		sudo tee "$nginx_config" > /dev/null << EOF
server {
    listen 8080;
    listen [::]:8080;
    
    server_name localhost;
    root $default_folder;
    index index.html index.htm index.php;
    
    # Enable directory listing
    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
    
    # PHP support (if PHP is installed)
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
    }
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    
    # Deny access to hidden files
    location ~ /\. {
        deny all;
    }
}
EOF
		
		# Enable the site
		sudo ln -sf "$nginx_config" /etc/nginx/sites-enabled/development
		
		# Disable default site to avoid conflicts
		sudo rm -f /etc/nginx/sites-enabled/default
		
		log_success "Development site configured on port 8080"
	else
		log_warning "sites-available directory not found, using default config"
	fi
}

start_nginx_service() {
	log_step "Starting Nginx service"
	
	# Test configuration
	if sudo nginx -t 2>/dev/null; then
		log_success "Nginx configuration test passed"
	else
		log_error "Nginx configuration test failed"
		return 1
	fi
	
	# Start and enable service
	if command -v systemctl >/dev/null 2>&1; then
		sudo systemctl enable nginx
		sudo systemctl restart nginx
		log_success "Nginx service started and enabled"
	else
		# Fallback for systems without systemctl
		sudo service nginx restart
		log_success "Nginx service restarted"
	fi
}

verify_installation() {
	log_step "Verifying Nginx installation"
	
	# Check if Nginx is running
	if systemctl is-active --quiet nginx 2>/dev/null; then
		log_success "Nginx service is running"
	else
		log_warning "Nginx service status unclear"
	fi
	
	# Check version
	if command -v nginx >/dev/null 2>&1; then
		local version
		version=$(nginx -v 2>&1 | cut -d'/' -f2)
		log_success "Nginx version: $version"
	fi
	
	# Test HTTP response
	if curl -s http://localhost:8080 >/dev/null 2>&1; then
		log_success "Nginx is responding on http://localhost:8080"
	else
		log_warning "Nginx is not responding on port 8080"
	fi
}

main() {
	log_info "Starting Nginx setup"
	
	install_nginx
	configure_nginx
	start_nginx_service
	verify_installation
	
	log_success "Nginx setup completed successfully"
	log_info "Access your development server at: http://localhost:8080"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
