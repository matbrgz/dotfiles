#!/bin/bash

# MongoDB Database Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="MongoDB Database Server"
CONFIG_FILE="$HOME/.bashrc"
MONGODB_DATA_DIR="$HOME/mongodb-data"

# Get version from version.json
get_mongodb_version() {
	mongodb_version=$(get_json_value "mongodb")
	if [[ -z "$mongodb_version" || "$mongodb_version" == "null" ]]; then
		mongodb_version="8.0.4"
	fi
	echo "$mongodb_version"
}

# Check if MongoDB is already installed
check_mongodb_installation() {
	if command -v mongod >/dev/null 2>&1; then
		log_warning "MongoDB is already installed"
		mongod --version | head -n1
		return 0
	fi
	return 1
}

# Install MongoDB
install_mongodb() {
	log_step "Installing MongoDB"
	
	local mongodb_version
	mongodb_version=$(get_mongodb_version)
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y wget curl gnupg lsb-release
			
			# Import MongoDB public GPG key
			curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
				sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
			
			# Add MongoDB repository
			local release_name
			release_name=$(lsb_release -cs)
			echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu $release_name/mongodb-org/8.0 multiverse" | \
				sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list
			
			# Update package list
			sudo apt-get update
			
			# Install MongoDB
			sudo apt-get install -y mongodb-org
			
			# Hold packages to prevent accidental upgrades
			echo "mongodb-org hold" | sudo dpkg --set-selections
			echo "mongodb-org-database hold" | sudo dpkg --set-selections
			echo "mongodb-org-server hold" | sudo dpkg --set-selections
			echo "mongodb-mongosh hold" | sudo dpkg --set-selections
			echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
			echo "mongodb-org-tools hold" | sudo dpkg --set-selections
			;;
		yay|pacman)
			# Install from AUR or official repositories
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm mongodb-bin
			else
				sudo pacman -S --noconfirm mongodb
			fi
			;;
		dnf)
			# Add MongoDB repository
			sudo tee /etc/yum.repos.d/mongodb-org-8.0.repo > /dev/null << 'EOF'
[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/8.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-8.0.asc
EOF
			
			sudo dnf install -y mongodb-org
			;;
		zypper)
			# Add MongoDB repository
			sudo zypper addrepo --gpgcheck --refresh https://repo.mongodb.org/zypper/suse/15/mongodb-org/8.0/x86_64/ mongodb
			sudo zypper --gpg-auto-import-keys refresh
			sudo zypper install -y mongodb-org
			;;
		brew)
			# Install MongoDB Community Edition
			brew tap mongodb/brew
			brew install mongodb-community
			;;
		*)
			log_warning "Package manager not supported, attempting binary installation"
			install_mongodb_binary
			;;
	esac
	
	log_success "MongoDB installed successfully"
}

# Install MongoDB from binary (fallback method)
install_mongodb_binary() {
	log_step "Installing MongoDB from binary"
	
	local mongodb_version arch os_name
	mongodb_version=$(get_mongodb_version)
	
	# Detect architecture and OS
	case "$(uname -m)" in
		x86_64) arch="x86_64" ;;
		aarch64|arm64) arch="arm64" ;;
		*) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
	esac
	
	case "$(uname -s)" in
		Linux) os_name="linux" ;;
		Darwin) os_name="macos" ;;
		*) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
	esac
	
	# Download and install MongoDB
	local download_url="https://fastdl.mongodb.org/${os_name}/mongodb-${os_name}-${arch}-${mongodb_version}.tgz"
	local temp_dir="/tmp/mongodb-install"
	
	mkdir -p "$temp_dir"
	cd "$temp_dir"
	
	log_step "Downloading MongoDB $mongodb_version"
	curl -fsSL "$download_url" -o "mongodb.tgz"
	
	log_step "Extracting MongoDB"
	tar -xzf "mongodb.tgz"
	
	# Install to /usr/local/bin
	local mongodb_dir=$(find . -name "mongodb-*" -type d | head -n1)
	sudo cp "$mongodb_dir/bin/"* /usr/local/bin/
	
	# Cleanup
	cd /
	rm -rf "$temp_dir"
	
	log_success "MongoDB binary installation completed"
}

# Configure MongoDB
configure_mongodb() {
	log_step "Configuring MongoDB"
	
	# Create data directory
	mkdir -p "$MONGODB_DATA_DIR"
	mkdir -p "$HOME/.mongodb/logs"
	
	# Create MongoDB configuration file
	local config_file="$HOME/.mongodb/mongod.conf"
	mkdir -p "$(dirname "$config_file")"
	
	cat > "$config_file" << EOF
# MongoDB Configuration File

# Storage settings
storage:
  dbPath: $MONGODB_DATA_DIR
  journal:
    enabled: true

# Network settings
net:
  port: 27017
  bindIp: 127.0.0.1

# Logging settings
systemLog:
  destination: file
  logAppend: true
  path: $HOME/.mongodb/logs/mongod.log

# Process management
processManagement:
  fork: true
  pidFilePath: $HOME/.mongodb/mongod.pid

# Security settings (development mode)
security:
  authorization: disabled

# Operation profiling
operationProfiling:
  slowOpThresholdMs: 100
  mode: slowOp
EOF
	
	log_success "MongoDB configuration created at $config_file"
}

# Setup MongoDB service scripts
setup_service_scripts() {
	log_step "Creating MongoDB service scripts"
	
	local bin_dir="$HOME/.local/bin"
	mkdir -p "$bin_dir"
	
	# Create start script
	cat > "$bin_dir/mongodb-start" << 'EOF'
#!/bin/bash
MONGODB_CONFIG="$HOME/.mongodb/mongod.conf"
MONGODB_PID="$HOME/.mongodb/mongod.pid"

if [[ -f "$MONGODB_PID" ]] && kill -0 "$(cat "$MONGODB_PID")" 2>/dev/null; then
    echo "MongoDB is already running (PID: $(cat "$MONGODB_PID"))"
    exit 0
fi

echo "Starting MongoDB..."
mongod --config "$MONGODB_CONFIG"

if [[ $? -eq 0 ]]; then
    echo "MongoDB started successfully"
    echo "Connection: mongodb://localhost:27017"
else
    echo "Failed to start MongoDB"
    exit 1
fi
EOF
	
	# Create stop script
	cat > "$bin_dir/mongodb-stop" << 'EOF'
#!/bin/bash
MONGODB_PID="$HOME/.mongodb/mongod.pid"

if [[ ! -f "$MONGODB_PID" ]]; then
    echo "MongoDB PID file not found. MongoDB may not be running."
    exit 1
fi

PID=$(cat "$MONGODB_PID")
if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping MongoDB (PID: $PID)..."
    kill -TERM "$PID"
    
    # Wait for process to terminate
    while kill -0 "$PID" 2>/dev/null; do
        sleep 1
    done
    
    rm -f "$MONGODB_PID"
    echo "MongoDB stopped successfully"
else
    echo "MongoDB process not found"
    rm -f "$MONGODB_PID"
fi
EOF
	
	# Create status script
	cat > "$bin_dir/mongodb-status" << 'EOF'
#!/bin/bash
MONGODB_PID="$HOME/.mongodb/mongod.pid"

if [[ -f "$MONGODB_PID" ]] && kill -0 "$(cat "$MONGODB_PID")" 2>/dev/null; then
    echo "MongoDB is running (PID: $(cat "$MONGODB_PID"))"
    echo "Connection: mongodb://localhost:27017"
    
    # Test connection
    if command -v mongosh >/dev/null 2>&1; then
        echo "Testing connection..."
        mongosh --quiet --eval "db.adminCommand('ismaster')" >/dev/null 2>&1 && \
            echo "✓ Connection successful" || echo "✗ Connection failed"
    fi
else
    echo "MongoDB is not running"
fi
EOF
	
	# Make scripts executable
	chmod +x "$bin_dir/mongodb-start" "$bin_dir/mongodb-stop" "$bin_dir/mongodb-status"
	
	# Add to PATH if not already there
	if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
		echo "export PATH=\"$bin_dir:\$PATH\"" >> "$CONFIG_FILE"
	fi
	
	log_success "MongoDB service scripts created"
}

# Create sample database and collections
create_sample_data() {
	log_step "Creating sample MongoDB project"
	
	local project_dir="$HOME/mongodb-sample-project"
	
	if [[ ! -d "$project_dir" ]]; then
		mkdir -p "$project_dir"
		cd "$project_dir"
		
		# Create sample data script
		cat > setup-sample-data.js << 'EOF'
// MongoDB Sample Data Setup

// Connect to sample database
use sampledb;

// Create users collection with sample data
db.users.insertMany([
    {
        name: "John Doe",
        email: "john@example.com",
        age: 30,
        role: "developer",
        skills: ["JavaScript", "Python", "MongoDB"],
        createdAt: new Date()
    },
    {
        name: "Jane Smith",
        email: "jane@example.com", 
        age: 28,
        role: "designer",
        skills: ["UI/UX", "Photoshop", "Figma"],
        createdAt: new Date()
    },
    {
        name: "Bob Johnson",
        email: "bob@example.com",
        age: 35,
        role: "manager",
        skills: ["Leadership", "Strategy", "Communication"],
        createdAt: new Date()
    }
]);

// Create products collection with sample data
db.products.insertMany([
    {
        name: "Laptop",
        category: "Electronics",
        price: 999.99,
        stock: 50,
        tags: ["computer", "portable", "work"],
        createdAt: new Date()
    },
    {
        name: "Coffee Mug",
        category: "Kitchen",
        price: 12.99,
        stock: 100,
        tags: ["drink", "ceramic", "office"],
        createdAt: new Date()
    },
    {
        name: "Book",
        category: "Education",
        price: 29.99,
        stock: 25,
        tags: ["reading", "learning", "paperback"],
        createdAt: new Date()
    }
]);

// Create indexes for better performance
db.users.createIndex({ email: 1 }, { unique: true });
db.users.createIndex({ role: 1 });
db.products.createIndex({ category: 1 });
db.products.createIndex({ name: "text" });

print("Sample data created successfully!");
print("Collections created: users, products");
print("Total users: " + db.users.countDocuments());
print("Total products: " + db.products.countDocuments());
EOF
		
		# Create query examples script
		cat > query-examples.js << 'EOF'
// MongoDB Query Examples

use sampledb;

print("=== MongoDB Query Examples ===");
print("");

// Basic queries
print("1. Find all users:");
db.users.find().pretty();

print("\n2. Find users with specific role:");
db.users.find({ role: "developer" }).pretty();

print("\n3. Find products under $30:");
db.products.find({ price: { $lt: 30 } }).pretty();

print("\n4. Count documents:");
print("Total users: " + db.users.countDocuments());
print("Total products: " + db.products.countDocuments());

print("\n5. Aggregation example - users by role:");
db.users.aggregate([
    { $group: { _id: "$role", count: { $sum: 1 } } }
]).pretty();

print("\n6. Text search example:");
db.products.find({ $text: { $search: "computer" } }).pretty();

print("\n7. Update example:");
var result = db.users.updateOne(
    { email: "john@example.com" },
    { $set: { lastLogin: new Date() } }
);
print("Modified count: " + result.modifiedCount);

print("\n8. Find with projection:");
db.users.find({}, { name: 1, email: 1, _id: 0 }).pretty();
EOF
		
		# Create README
		cat > README.md << 'EOF'
# MongoDB Sample Project

Sample MongoDB database with example data and queries.

## Setup Sample Data

1. Start MongoDB:
   ```bash
   mongodb-start
   ```

2. Load sample data:
   ```bash
   mongosh < setup-sample-data.js
   ```

3. Run query examples:
   ```bash
   mongosh < query-examples.js
   ```

## Basic Commands

```bash
# Start MongoDB
mongodb-start

# Check status
mongodb-status

# Connect to MongoDB
mongosh

# Stop MongoDB
mongodb-stop
```

## Sample Queries

```javascript
// Connect to sample database
use sampledb;

// Find all users
db.users.find().pretty();

// Find products by category
db.products.find({ category: "Electronics" });

// Count documents
db.users.countDocuments();

// Create new user
db.users.insertOne({
    name: "New User",
    email: "newuser@example.com",
    age: 25,
    role: "tester"
});
```

## Configuration

- Data directory: ~/mongodb-data
- Config file: ~/.mongodb/mongod.conf
- Log file: ~/.mongodb/logs/mongod.log
- Default port: 27017
EOF
		
		log_success "Sample MongoDB project created at $project_dir"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating MongoDB aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for MongoDB
	local mongodb_aliases="
# MongoDB Aliases
alias mongo-start='mongodb-start'
alias mongo-stop='mongodb-stop'
alias mongo-status='mongodb-status'
alias mongo-connect='mongosh'
alias mongo-logs='tail -f ~/.mongodb/logs/mongod.log'
alias mongo-config='cat ~/.mongodb/mongod.conf'
alias mongo-data='ls -la $MONGODB_DATA_DIR'
alias mongo-version='mongod --version'
alias mongoshell='mongosh'
alias mongo-sample='cd $HOME/mongodb-sample-project'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "MongoDB Aliases" "$alias_file"; then
			echo "$mongodb_aliases" >> "$alias_file"
		fi
	else
		echo "$mongodb_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "MongoDB aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying MongoDB installation"
	
	if command -v mongod >/dev/null 2>&1; then
		log_success "MongoDB installed successfully!"
		echo "  Version: $(mongod --version | head -n1)"
		echo "  Data directory: $MONGODB_DATA_DIR"
		echo "  Configuration: $HOME/.mongodb/mongod.conf"
		
		if command -v mongosh >/dev/null 2>&1; then
			echo "  MongoDB Shell: $(mongosh --version | head -n1)"
		fi
		
		return 0
	else
		log_error "MongoDB installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

MongoDB Database Usage:
======================

Service Management:
  mongodb-start               Start MongoDB server
  mongodb-stop                Stop MongoDB server
  mongodb-status              Check MongoDB status

Connection:
  mongosh                     Connect to MongoDB shell
  mongosh "mongodb://localhost:27017/mydb"  Connect to specific database

Basic Commands (in MongoDB shell):
  show dbs                    List databases
  use mydb                    Switch to database
  show collections            List collections
  db.mycollection.find()      Find documents
  db.mycollection.insertOne({}) Insert document

Useful Aliases:
  mongo-start                 Start MongoDB
  mongo-stop                  Stop MongoDB
  mongo-status                Check status
  mongo-connect               Connect to shell
  mongo-logs                  View logs
  mongo-sample                Go to sample project

Configuration Files:
  ~/.mongodb/mongod.conf      MongoDB configuration
  ~/.mongodb/logs/mongod.log  MongoDB logs
  ~/mongodb-data/             Data directory

Sample Project:
  ~/mongodb-sample-project/   Example database and queries

For more information: https://docs.mongodb.com/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_mongodb_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure MongoDB
	install_mongodb
	configure_mongodb
	setup_service_scripts
	
	# Create sample data and aliases
	create_sample_data
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Use 'mongodb-start' to start the MongoDB server"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
