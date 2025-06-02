#!/bin/bash

# PostgreSQL Database Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="PostgreSQL Database Server"
CONFIG_FILE="$HOME/.bashrc"
POSTGRES_DATA_DIR="$HOME/postgres-data"

# Get version from version.json
get_postgresql_version() {
	postgresql_version=$(get_json_value "postgresql")
	if [[ -z "$postgresql_version" || "$postgresql_version" == "null" ]]; then
		postgresql_version="17.2.0"
	fi
	echo "$postgresql_version"
}

# Check if PostgreSQL is already installed
check_postgresql_installation() {
	if command -v psql >/dev/null 2>&1; then
		log_warning "PostgreSQL is already installed"
		psql --version
		return 0
	fi
	return 1
}

# Install PostgreSQL
install_postgresql() {
	log_step "Installing PostgreSQL"
	
	local postgresql_version
	postgresql_version=$(get_postgresql_version)
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y wget ca-certificates
			
			# Add PostgreSQL official APT repository
			wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
			echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" | \
				sudo tee /etc/apt/sources.list.d/pgdg.list
			
			# Update package list
			sudo apt-get update
			
			# Install PostgreSQL
			sudo apt-get install -y postgresql postgresql-contrib postgresql-client \
				postgresql-client-common postgresql-common libpq-dev
			;;
		yay|pacman)
			sudo pacman -S --needed --noconfirm postgresql postgresql-libs
			;;
		dnf)
			sudo dnf install -y postgresql postgresql-server postgresql-contrib \
				postgresql-devel libpq-devel
			;;
		zypper)
			sudo zypper install -y postgresql postgresql-server postgresql-contrib \
				postgresql-devel libpq5-devel
			;;
		brew)
			brew install postgresql@15
			brew services start postgresql@15
			;;
		*)
			log_error "Package manager not supported for PostgreSQL installation"
			return 1
			;;
	esac
	
	log_success "PostgreSQL installed successfully"
}

# Configure PostgreSQL
configure_postgresql() {
	log_step "Configuring PostgreSQL"
	
	# Create data directory
	mkdir -p "$POSTGRES_DATA_DIR"
	
	# Initialize PostgreSQL database cluster if needed
	if [[ ! -d "$POSTGRES_DATA_DIR/base" ]]; then
		log_step "Initializing PostgreSQL database cluster"
		initdb -D "$POSTGRES_DATA_DIR" --auth-local=trust --auth-host=scram-sha-256
	fi
	
	# Create PostgreSQL configuration
	local config_dir="$HOME/.postgresql"
	mkdir -p "$config_dir"
	
	# Create custom postgresql.conf
	cat > "$config_dir/postgresql.conf" << EOF
# PostgreSQL Configuration File

# Connection settings
listen_addresses = 'localhost'
port = 5432
max_connections = 100

# Memory settings
shared_buffers = 128MB
effective_cache_size = 512MB
work_mem = 4MB
maintenance_work_mem = 64MB

# Logging settings
log_destination = 'stderr'
logging_collector = on
log_directory = '$HOME/.postgresql/logs'
log_filename = 'postgresql-%Y-%m-%d.log'
log_rotation_age = 1d
log_rotation_size = 10MB
log_statement = 'all'
log_duration = on
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '

# WAL settings
wal_level = replica
max_wal_size = 1GB
min_wal_size = 80MB

# Checkpoint settings
checkpoint_completion_target = 0.9
wal_buffers = 16MB

# Performance settings
random_page_cost = 1.1
seq_page_cost = 1.0
default_statistics_target = 100

# Timezone
timezone = 'UTC'

# Locale
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'
EOF
	
	# Create pg_hba.conf for authentication
	cat > "$config_dir/pg_hba.conf" << EOF
# PostgreSQL Client Authentication Configuration File

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# Local connections
local   all             all                                     trust
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256

# Development connections (adjust as needed)
host    all             all             0.0.0.0/0               scram-sha-256
EOF
	
	# Create logs directory
	mkdir -p "$HOME/.postgresql/logs"
	
	log_success "PostgreSQL configuration created"
}

# Setup PostgreSQL service scripts
setup_service_scripts() {
	log_step "Creating PostgreSQL service scripts"
	
	local bin_dir="$HOME/.local/bin"
	mkdir -p "$bin_dir"
	
	# Create start script
	cat > "$bin_dir/postgresql-start" << EOF
#!/bin/bash
POSTGRES_DATA_DIR="$POSTGRES_DATA_DIR"
POSTGRES_CONFIG="$HOME/.postgresql/postgresql.conf"
POSTGRES_PID="\$POSTGRES_DATA_DIR/postmaster.pid"

if [[ -f "\$POSTGRES_PID" ]] && kill -0 "\$(cat "\$POSTGRES_PID")" 2>/dev/null; then
    echo "PostgreSQL is already running (PID: \$(cat "\$POSTGRES_PID"))"
    exit 0
fi

echo "Starting PostgreSQL..."
pg_ctl -D "\$POSTGRES_DATA_DIR" -l "\$HOME/.postgresql/logs/postgresql.log" start

if [[ \$? -eq 0 ]]; then
    echo "PostgreSQL started successfully"
    echo "Connection: postgresql://localhost:5432"
    echo "Data directory: \$POSTGRES_DATA_DIR"
else
    echo "Failed to start PostgreSQL"
    exit 1
fi
EOF
	
	# Create stop script
	cat > "$bin_dir/postgresql-stop" << EOF
#!/bin/bash
POSTGRES_DATA_DIR="$POSTGRES_DATA_DIR"

echo "Stopping PostgreSQL..."
pg_ctl -D "\$POSTGRES_DATA_DIR" stop

if [[ \$? -eq 0 ]]; then
    echo "PostgreSQL stopped successfully"
else
    echo "Failed to stop PostgreSQL"
    exit 1
fi
EOF
	
	# Create status script
	cat > "$bin_dir/postgresql-status" << EOF
#!/bin/bash
POSTGRES_DATA_DIR="$POSTGRES_DATA_DIR"
POSTGRES_PID="\$POSTGRES_DATA_DIR/postmaster.pid"

if [[ -f "\$POSTGRES_PID" ]] && kill -0 "\$(cat "\$POSTGRES_PID")" 2>/dev/null; then
    echo "PostgreSQL is running (PID: \$(cat "\$POSTGRES_PID"))"
    echo "Connection: postgresql://localhost:5432"
    
    # Test connection
    if command -v psql >/dev/null 2>&1; then
        echo "Testing connection..."
        psql -h localhost -p 5432 -d postgres -c "SELECT version();" >/dev/null 2>&1 && \
            echo "✓ Connection successful" || echo "✗ Connection failed"
    fi
else
    echo "PostgreSQL is not running"
fi
EOF
	
	# Create database initialization script
	cat > "$bin_dir/postgresql-init" << 'EOF'
#!/bin/bash

echo "Initializing PostgreSQL development environment..."

# Create development user
psql -h localhost -p 5432 -d postgres -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'dev') THEN
        CREATE ROLE dev WITH LOGIN PASSWORD 'dev123' CREATEDB;
    END IF;
END
\$\$;
"

# Create development database
psql -h localhost -p 5432 -d postgres -c "
SELECT 'CREATE DATABASE devdb OWNER dev'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'devdb')\gexec
"

# Grant privileges
psql -h localhost -p 5432 -d postgres -c "
GRANT ALL PRIVILEGES ON DATABASE devdb TO dev;
ALTER USER dev CREATEDB;
"

echo "Development environment initialized:"
echo "  Database: devdb"
echo "  User: dev"
echo "  Password: dev123"
echo "  Connection: postgresql://dev:dev123@localhost:5432/devdb"
EOF
	
	# Make scripts executable
	chmod +x "$bin_dir/postgresql-start" "$bin_dir/postgresql-stop" \
		"$bin_dir/postgresql-status" "$bin_dir/postgresql-init"
	
	# Add to PATH if not already there
	if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
		echo "export PATH=\"$bin_dir:\$PATH\"" >> "$CONFIG_FILE"
	fi
	
	log_success "PostgreSQL service scripts created"
}

# Create sample database and tables
create_sample_data() {
	log_step "Creating sample PostgreSQL project"
	
	local project_dir="$HOME/postgresql-sample-project"
	
	if [[ ! -d "$project_dir" ]]; then
		mkdir -p "$project_dir"
		cd "$project_dir"
		
		# Create sample data script
		cat > setup-sample-data.sql << 'EOF'
-- PostgreSQL Sample Data Setup

-- Connect to development database
\c devdb;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    age INTEGER CHECK (age >= 0 AND age <= 150),
    role VARCHAR(50) NOT NULL,
    skills TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create products table
CREATE TABLE IF NOT EXISTS products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    price DECIMAL(10,2) CHECK (price >= 0),
    stock INTEGER DEFAULT 0 CHECK (stock >= 0),
    tags TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(id) ON DELETE CASCADE,
    quantity INTEGER DEFAULT 1 CHECK (quantity > 0),
    total_price DECIMAL(10,2),
    order_date TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert sample users
INSERT INTO users (name, email, age, role, skills) VALUES
    ('John Doe', 'john@example.com', 30, 'developer', ARRAY['JavaScript', 'Python', 'PostgreSQL']),
    ('Jane Smith', 'jane@example.com', 28, 'designer', ARRAY['UI/UX', 'Photoshop', 'Figma']),
    ('Bob Johnson', 'bob@example.com', 35, 'manager', ARRAY['Leadership', 'Strategy', 'Communication'])
ON CONFLICT (email) DO NOTHING;

-- Insert sample products
INSERT INTO products (name, category, price, stock, tags) VALUES
    ('Laptop', 'Electronics', 999.99, 50, ARRAY['computer', 'portable', 'work']),
    ('Coffee Mug', 'Kitchen', 12.99, 100, ARRAY['drink', 'ceramic', 'office']),
    ('Book', 'Education', 29.99, 25, ARRAY['reading', 'learning', 'paperback'])
ON CONFLICT DO NOTHING;

-- Insert sample orders
INSERT INTO orders (user_id, product_id, quantity, total_price) 
SELECT 
    u.id, 
    p.id, 
    1, 
    p.price
FROM users u 
CROSS JOIN products p 
WHERE u.email = 'john@example.com' AND p.name = 'Laptop'
ON CONFLICT DO NOTHING;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);

-- Create full-text search index
CREATE INDEX IF NOT EXISTS idx_products_name_search ON products USING GIN(to_tsvector('english', name));

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for automatic timestamp updates
DROP TRIGGER IF EXISTS update_users_updated_at ON users;
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at 
    BEFORE UPDATE ON products 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

\echo 'Sample data created successfully!'
\echo 'Tables created: users, products, orders'
SELECT 'Users: ' || count(*) FROM users;
SELECT 'Products: ' || count(*) FROM products;
SELECT 'Orders: ' || count(*) FROM orders;
EOF
		
		# Create query examples script
		cat > query-examples.sql << 'EOF'
-- PostgreSQL Query Examples

\c devdb;

\echo '=== PostgreSQL Query Examples ==='
\echo ''

-- Basic queries
\echo '1. Find all users:'
SELECT * FROM users;

\echo ''
\echo '2. Find users with specific role:'
SELECT * FROM users WHERE role = 'developer';

\echo ''
\echo '3. Find products under $30:'
SELECT * FROM products WHERE price < 30;

\echo ''
\echo '4. Count records:'
SELECT 'Total users: ' || count(*) FROM users;
SELECT 'Total products: ' || count(*) FROM products;

\echo ''
\echo '5. Join example - orders with user and product info:'
SELECT 
    u.name as user_name,
    p.name as product_name,
    o.quantity,
    o.total_price,
    o.order_date
FROM orders o
JOIN users u ON o.user_id = u.id
JOIN products p ON o.product_id = p.id;

\echo ''
\echo '6. Aggregation example - users by role:'
SELECT role, count(*) as user_count 
FROM users 
GROUP BY role;

\echo ''
\echo '7. Full-text search example:'
SELECT * FROM products 
WHERE to_tsvector('english', name) @@ to_tsquery('english', 'computer');

\echo ''
\echo '8. Array operations:'
SELECT name, skills 
FROM users 
WHERE 'JavaScript' = ANY(skills);

\echo ''
\echo '9. Update example:'
UPDATE users 
SET skills = array_append(skills, 'SQL') 
WHERE email = 'john@example.com';

\echo ''
\echo '10. Window function example:'
SELECT 
    name, 
    price,
    category,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY price DESC) as rank
FROM products;
EOF
		
		# Create README
		cat > README.md << 'EOF'
# PostgreSQL Sample Project

Sample PostgreSQL database with example data and queries.

## Setup Sample Data

1. Start PostgreSQL:
   ```bash
   postgresql-start
   ```

2. Initialize development environment:
   ```bash
   postgresql-init
   ```

3. Load sample data:
   ```bash
   psql -h localhost -p 5432 -d devdb -f setup-sample-data.sql
   ```

4. Run query examples:
   ```bash
   psql -h localhost -p 5432 -d devdb -f query-examples.sql
   ```

## Basic Commands

```bash
# Start PostgreSQL
postgresql-start

# Check status
postgresql-status

# Connect to PostgreSQL
psql -h localhost -p 5432 -d devdb -U dev

# Stop PostgreSQL
postgresql-stop
```

## Sample Queries

```sql
-- Connect to development database
\c devdb;

-- Find all users
SELECT * FROM users;

-- Find products by category
SELECT * FROM products WHERE category = 'Electronics';

-- Count records
SELECT count(*) FROM users;

-- Create new user
INSERT INTO users (name, email, age, role, skills) 
VALUES ('New User', 'newuser@example.com', 25, 'tester', ARRAY['Testing', 'QA']);
```

## Development Environment

- Database: devdb
- User: dev
- Password: dev123
- Connection: postgresql://dev:dev123@localhost:5432/devdb

## Configuration

- Data directory: ~/postgres-data
- Config file: ~/.postgresql/postgresql.conf
- Log directory: ~/.postgresql/logs/
- Default port: 5432
EOF
		
		log_success "Sample PostgreSQL project created at $project_dir"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating PostgreSQL aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for PostgreSQL
	local postgresql_aliases="
# PostgreSQL Aliases
alias pg-start='postgresql-start'
alias pg-stop='postgresql-stop'
alias pg-status='postgresql-status'
alias pg-init='postgresql-init'
alias pg-connect='psql -h localhost -p 5432 -d devdb -U dev'
alias pg-admin='psql -h localhost -p 5432 -d postgres'
alias pg-logs='tail -f ~/.postgresql/logs/postgresql.log'
alias pg-config='cat ~/.postgresql/postgresql.conf'
alias pg-data='ls -la $POSTGRES_DATA_DIR'
alias pg-version='psql --version'
alias pg-sample='cd $HOME/postgresql-sample-project'
alias psqldev='psql -h localhost -p 5432 -d devdb -U dev'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "PostgreSQL Aliases" "$alias_file"; then
			echo "$postgresql_aliases" >> "$alias_file"
		fi
	else
		echo "$postgresql_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "PostgreSQL aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying PostgreSQL installation"
	
	if command -v psql >/dev/null 2>&1; then
		log_success "PostgreSQL installed successfully!"
		echo "  Version: $(psql --version)"
		echo "  Data directory: $POSTGRES_DATA_DIR"
		echo "  Configuration: $HOME/.postgresql/postgresql.conf"
		
		if command -v pg_ctl >/dev/null 2>&1; then
			echo "  Control utility: $(pg_ctl --version | head -n1)"
		fi
		
		return 0
	else
		log_error "PostgreSQL installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

PostgreSQL Database Usage:
=========================

Service Management:
  postgresql-start            Start PostgreSQL server
  postgresql-stop             Stop PostgreSQL server
  postgresql-status           Check PostgreSQL status
  postgresql-init             Initialize development environment

Connection:
  psql -h localhost -p 5432 -d postgres  Connect as superuser
  psql -h localhost -p 5432 -d devdb -U dev  Connect as dev user

Basic Commands (in psql):
  \l                          List databases
  \c dbname                   Connect to database
  \dt                         List tables
  \d tablename                Describe table
  \q                          Quit psql

Development Environment:
  Database: devdb
  User: dev
  Password: dev123
  Connection: postgresql://dev:dev123@localhost:5432/devdb

Useful Aliases:
  pg-start                    Start PostgreSQL
  pg-stop                     Stop PostgreSQL
  pg-status                   Check status
  pg-connect                  Connect as dev user
  pg-admin                    Connect as admin
  pg-logs                     View logs
  pg-sample                   Go to sample project

Configuration Files:
  ~/.postgresql/postgresql.conf    PostgreSQL configuration
  ~/.postgresql/pg_hba.conf        Authentication configuration
  ~/.postgresql/logs/              Log files
  ~/postgres-data/                 Data directory

Sample Project:
  ~/postgresql-sample-project/     Example database and queries

For more information: https://www.postgresql.org/docs/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_postgresql_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure PostgreSQL
	install_postgresql
	configure_postgresql
	setup_service_scripts
	
	# Create sample data and aliases
	create_sample_data
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Use 'postgresql-start' to start the PostgreSQL server"
		log_warning "Use 'postgresql-init' to setup development environment"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
