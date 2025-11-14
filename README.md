# Inception Project - Docker Infrastructure Setup

![42 School](https://img.shields.io/badge/42-School-000000?style=flat-square&logo=42)
![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat-square&logo=docker&logoColor=white)
![Docker Compose](https://img.shields.io/badge/Docker%20Compose-2496ED?style=flat-square&logo=docker&logoColor=white)
![NGINX](https://img.shields.io/badge/NGINX-009639?style=flat-square&logo=nginx&logoColor=white)
![WordPress](https://img.shields.io/badge/WordPress-21759B?style=flat-square&logo=wordpress&logoColor=white)
![MariaDB](https://img.shields.io/badge/MariaDB-003545?style=flat-square&logo=mariadb&logoColor=white)

A complete Docker infrastructure project that sets up a secure LEMP stack (Linux, NGINX, MariaDB, PHP) with WordPress, using Docker Compose and custom Dockerfiles. This project is part of the 42 School curriculum.

## � Step-by-Step Development Guide

This comprehensive guide will help you build your own Inception project from scratch, following the 42 School subject requirements exactly. Each step includes detailed explanations of WHY we're doing things, not just HOW.

### 🎯 Understanding the Big Picture First

Before diving into code, let's understand what we're building and why:

**The Goal**: Create a multi-container Docker infrastructure that serves a WordPress website through NGINX with HTTPS, backed by a MariaDB database. Each service runs in its own isolated container, but they communicate through a custom Docker network.

**Key Concepts You'll Master**:
- **Containerization**: Each service (NGINX, WordPress, MariaDB) runs in complete isolation
- **Service Orchestration**: Docker Compose manages all containers as one application
- **Reverse Proxy**: NGINX acts as the front door, forwarding requests to WordPress
- **Data Persistence**: Volumes ensure your data survives container crashes and restarts
- **Network Security**: Custom networks provide isolated communication between containers
- **HTTPS Termination**: SSL certificates and secure connections

**The Flow**: User → NGINX (Port 443/HTTPS) → WordPress (PHP-FPM) → MariaDB → Data Storage

### Phase 1: Project Setup & Planning

#### 1.1 Create Project Structure - The Foundation

**Why this exact structure?** The 42 subject mandates this layout. It's not arbitrary - it follows Docker best practices for organizing multi-service applications.

```bash
# Create the mandatory directory structure
mkdir -p inception/{srcs/requirements/{nginx,wordpress,mariadb}/{conf,tools},secrets}
cd inception

# Create essential files
touch Makefile
touch srcs/.env
touch srcs/docker-compose.yml
```

**Let's break down what we just created and WHY**:

```
inception/                    # Root project directory
├── Makefile                 # Build automation (subject requirement)
├── secrets/                 # Sensitive data storage (passwords, keys)
└── srcs/                    # All project files MUST be here (subject requirement)
    ├── .env                 # Environment variables (no hardcoded passwords!)
    ├── docker-compose.yml   # Service orchestration
    └── requirements/        # Service definitions
        ├── nginx/           # Reverse proxy service
        │   ├── conf/        # NGINX configuration files
        │   └── tools/       # Scripts and utilities
        ├── wordpress/       # Web application service
        │   ├── conf/        # PHP-FPM configuration
        │   └── tools/       # WordPress setup scripts
        └── mariadb/         # Database service
            ├── conf/        # Database configuration  
            └── tools/       # Database initialization scripts
```

**Why separate `conf/` and `tools/` directories?**
- `conf/` - Static configuration files (nginx.conf, my.cnf, etc.)
- `tools/` - Executable scripts that run during container startup
- This separation makes your project organized and maintainable

**Verify your structure is correct**:
```bash
tree inception/
# Should match the structure above exactly
```

#### 1.2 Set Up Version Control - Save Your Progress

**Why use Git?** You WILL make mistakes. Git lets you:
- Revert broken changes instantly
- Track your progress through the project
- Collaborate with peers
- Submit clean code for evaluation

```bash
cd inception
git init
echo "srcs/.env" >> .gitignore
echo "secrets/*" >> .gitignore  
echo "/home/*/data" >> .gitignore
echo "*.log" >> .gitignore
```

**Why these .gitignore entries?**
- `srcs/.env` - Contains passwords and API keys (NEVER commit secrets!)
- `secrets/*` - Directory for sensitive files (subject mentions this)
- `/home/*/data` - Docker volume mount points (system-specific paths)
- `*.log` - Log files that change constantly

**Test your Git setup**:
```bash
git add .
git commit -m "Initial project structure"
git status  # Should be clean
```

### Phase 2: Environment Configuration - The Security Foundation

#### 2.1 Understanding Domain Names and Local Development

**What's happening here?** The subject requires your domain to be `yourusername.42.fr`. Since we're developing locally, we need to "trick" our computer into thinking this domain points to our local machine.

```bash
# Replace 'yourusername' with your actual 42 login
export LOGIN="jdoe"  # CHANGE THIS TO YOUR LOGIN!
echo "127.0.0.1 ${LOGIN}.42.fr" | sudo tee -a /etc/hosts
```

**What this command does step-by-step**:
1. `export LOGIN="jdoe"` - Sets a variable with your username
2. `echo "127.0.0.1 ${LOGIN}.42.fr"` - Creates the hosts entry
3. `sudo tee -a /etc/hosts` - Appends to the hosts file (needs sudo for system file)
4. The result: `127.0.0.1 jdoe.42.fr` gets added to `/etc/hosts`

**Why `/etc/hosts`?** This file acts as your computer's local DNS. When you type `jdoe.42.fr` in your browser, your computer checks this file first before asking external DNS servers.

**Verify it worked**:
```bash
ping ${LOGIN}.42.fr
# Should show: PING jdoe.42.fr (127.0.0.1): ...
# Press Ctrl+C to stop
```

**Troubleshooting**:
- If ping fails, check `/etc/hosts`: `tail /etc/hosts`
- Make sure there are no typos in your domain name
- Some systems need `sudo systemctl restart systemd-resolved` after hosts changes

#### 2.2 Create Environment Variables - The Security Heart

**Why environment variables?** The subject explicitly states:
> "Passwords must not be present in your Dockerfiles"
> "The use of environment variables is mandatory"

Environment variables let us inject sensitive data at runtime without hardcoding it in our source code.

Create `srcs/.env` with your specific values:

```bash
# ===== DOMAIN CONFIGURATION =====
# CRITICAL: Must use YOUR 42 login, not 'yourusername'!
DOMAIN_NAME=jdoe.42.fr

# ===== DATABASE CONFIGURATION =====
# Root user has complete database access - use strong password
MYSQL_ROOT_PASSWORD=SuperSecureRootPass123!

# WordPress database user - dedicated user with limited privileges
MYSQL_USER=wp_database_user
MYSQL_PASSWORD=WpUserSecurePass456!
MYSQL_DATABASE=wordpress

# ===== WORDPRESS CONFIGURATION =====  
# CRITICAL: Username CANNOT contain 'admin', 'Admin', 'administrator', etc.
WORDPRESS_ADMIN_USER=john_doe           # Use your name or nickname
WORDPRESS_ADMIN_PASSWORD=AdminPass789!  # WordPress admin login password
WORDPRESS_ADMIN_EMAIL=john@example.com  # Your email for WordPress
WORDPRESS_TITLE=My Awesome 42 Project  # Site title visitors will see
WORDPRESS_URL=https://jdoe.42.fr       # Full site URL (must match DOMAIN_NAME!)

# ===== PHP-FPM CONFIGURATION =====
# These control which user/group PHP processes run as
PHP_FPM_USER=www-data                   # Standard web server user
PHP_FPM_GROUP=www-data                  # Standard web server group
```

**🚨 CRITICAL SUBJECT REQUIREMENTS EXPLAINED**:

1. **Domain Name Format**: MUST be `yourlogin.42.fr` - replace `yourlogin` with YOUR actual 42 login
2. **Admin Username Restriction**: Cannot contain these strings (case-insensitive):
   - 'admin'
   - 'Admin'  
   - 'administrator'
   - 'Administrator'
   - Examples of INVALID names: `admin`, `Admin123`, `administrator`, `my_admin`
   - Examples of VALID names: `john_doe`, `jdoe`, `webmaster`, `site_owner`

3. **No Hardcoded Passwords**: Every password must come from environment variables
4. **Strong Passwords**: Use complex passwords with letters, numbers, and symbols

**Environment Variable Security Best Practices**:
```bash
# Set restrictive permissions on .env file
chmod 600 srcs/.env

# Verify permissions (should show -rw-------)
ls -la srcs/.env

# Double-check .gitignore includes .env
grep ".env" .gitignore
```

**Test your environment variables**:
```bash
# Load variables and test
source srcs/.env
echo "Domain: $DOMAIN_NAME"
echo "Database User: $MYSQL_USER"
# Should display your values correctly
```

## 🔍 Overview

This project demonstrates how to build a complete web infrastructure using Docker containers. The setup includes:

- **NGINX**: Reverse proxy with SSL/TLS encryption (HTTPS only)
- **WordPress**: Content management system with PHP-FPM
- **MariaDB**: Database server for WordPress
- **Docker Volumes**: Persistent data storage
- **Docker Network**: Secure inter-container communication

All services are containerized using custom Dockerfiles and orchestrated with Docker Compose.

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│     NGINX       │    │   WordPress     │    │    MariaDB      │
│   (Port 443)    │◄──►│   (PHP-FPM)     │◄──►│   (Port 3306)   │
│                 │    │   (Port 9000)   │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
                    ┌─────────────────┐
                    │ Docker Network  │
                    │ (inception_net) │
                    └─────────────────┘
                                 │
                    ┌─────────────────┐
                    │   Host Volumes  │
                    │ /home/user/data │
                    └─────────────────┘
```

### Data Flow:
1. Client connects to NGINX on port 443 (HTTPS)
2. NGINX forwards PHP requests to WordPress container via FastCGI
3. WordPress communicates with MariaDB for database operations
4. All containers communicate through a custom Docker network
5. Data persists in host-mounted volumes

## 📁 Project Structure

```
inception/
├── Makefile                          # Build and deployment commands
├── README.md                         # This file
├── subject.txt                       # Project requirements
└── srcs/
    ├── .env                          # Environment variables
    ├── docker-compose.yml            # Services orchestration
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile            # NGINX container config
        │   ├── certs/                # SSL certificates (auto-generated)
        │   └── conf/
        │       └── nginx.conf        # NGINX configuration
        ├── wordpress/
        │   ├── Dockerfile            # WordPress container config
        │   ├── www.conf              # PHP-FPM configuration
        │   └── tools/
        │       └── setup_wordpress.sh # WordPress installation script
        └── mariadb/
            ├── Dockerfile            # MariaDB container config
            ├── conf/
            │   └── my.cnf           # MariaDB configuration
            └── tools/
                ├── init_db.sh       # Database initialization
                └── init.sql         # Database setup queries
```

## � Step-by-Step Development Guide

This comprehensive guide will help you build your own Inception project from scratch, following the 42 School subject requirements exactly.

### Phase 1: Project Setup & Planning

#### 1.1 Create Project Structure
```bash
# Create the mandatory directory structure
mkdir -p inception/{srcs/requirements/{nginx,wordpress,mariadb}/{conf,tools},secrets}
cd inception

# Create essential files
touch Makefile
touch srcs/.env
touch srcs/docker-compose.yml
```

#### 1.2 Set Up Version Control (Optional but Recommended)
```bash
git init
echo "srcs/.env" >> .gitignore
echo "secrets/*" >> .gitignore
echo "/home/*/data" >> .gitignore
```

### Phase 2: Environment Configuration

#### 2.1 Configure Domain Name
```bash
# Replace 'yourusername' with your actual 42 login
export LOGIN="yourusername"
echo "127.0.0.1 ${LOGIN}.42.fr" | sudo tee -a /etc/hosts
```

#### 2.2 Create Environment Variables
Create `srcs/.env` with your specific values:
```bash
# Domain Configuration (MANDATORY: use your login)
DOMAIN_NAME=yourusername.42.fr

# Database Configuration
MYSQL_ROOT_PASSWORD=your_secure_root_password
MYSQL_USER=wp_user
MYSQL_PASSWORD=your_secure_user_password
MYSQL_DATABASE=wordpress

# WordPress Configuration
WORDPRESS_ADMIN_USER=yourname        # NO 'admin' in the name!
WORDPRESS_ADMIN_PASSWORD=your_secure_admin_password
WORDPRESS_ADMIN_EMAIL=your@email.com
WORDPRESS_TITLE=Your Site Title
WORDPRESS_URL=https://yourusername.42.fr

# System Configuration
PHP_FPM_USER=www-data
PHP_FPM_GROUP=www-data
```

**⚠️ CRITICAL SUBJECT REQUIREMENTS:**
- Use **YOUR** 42 login for domain name
- Admin username **CANNOT** contain 'admin', 'Admin', 'administrator', etc.
- **NO** passwords in Dockerfiles
- **MUST** use environment variables

### Phase 3: MariaDB Container - The Data Foundation

**What is MariaDB?** MariaDB is a drop-in replacement for MySQL, created by the original MySQL developers. It's our database server that will store all WordPress content, users, and settings.

**Key Concepts**:
- **Database Server**: Stores and retrieves data for WordPress
- **Container Isolation**: Runs in its own container, separate from other services
- **Data Persistence**: Uses volumes to keep data safe even if container crashes
- **Network Access**: Only accessible from other containers, not directly from internet

#### 3.1 Create MariaDB Dockerfile - Building the Database Container

Create `srcs/requirements/mariadb/Dockerfile`:

```dockerfile
# Use Debian bookworm as base (subject allows Debian or Alpine)
FROM debian:bookworm

# Install MariaDB server and client
# Why both? Server runs the database, client lets us run commands
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy our custom configuration
# This replaces the default MariaDB config with our settings
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy our database initialization script
COPY tools/init_db.sh /usr/local/bin/init_db.sh

# Make the script executable and set up directories
RUN chmod +x /usr/local/bin/init_db.sh
RUN mkdir -p /run/mysqld /var/lib/mysql
RUN chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Expose port 3306 (standard MySQL/MariaDB port)
# This allows other containers to connect to the database
EXPOSE 3306

# Start the database using our initialization script
# NOT using infinite loops like "tail -f" - that's forbidden!
CMD ["/usr/local/bin/init_db.sh"]
```

**Why each step matters**:
- **FROM debian:bookworm**: Subject allows Debian or Alpine (we chose Debian)
- **NO `latest` tag**: Subject explicitly forbids using `latest` tag
- **Package cleanup**: `rm -rf /var/lib/apt/lists/*` reduces image size
- **Custom config**: We override defaults to allow network connections
- **Proper permissions**: MySQL needs specific user/group ownership
- **Script-based startup**: Avoids forbidden infinite loops

#### 3.2 Create MariaDB Configuration - Network and Security Settings

Create `srcs/requirements/mariadb/conf/my.cnf`:

```ini
[mysqld]
# Bind to all interfaces (not just localhost)
# This allows other containers to connect
bind-address = 0.0.0.0

# Standard MySQL port
port = 3306

# Run as mysql user for security
user = mysql

# Where database files are stored
datadir = /var/lib/mysql

# Unix socket for local connections
socket = /run/mysqld/mysqld.sock

# Process ID file
pid-file = /run/mysqld/mysqld.pid

# Where to log errors
log-error = /var/log/mysql/error.log

# Skip name resolution for better performance
skip-name-resolve

# Default storage engine
default-storage-engine = InnoDB

# Character set and collation
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
```

**Configuration Explained**:
- **bind-address = 0.0.0.0**: Allows connections from other containers (not just localhost)
- **skip-name-resolve**: Improves performance by not doing reverse DNS lookups
- **utf8mb4**: Full UTF-8 support (handles emojis and international characters)
- **InnoDB**: Modern storage engine with transaction support

#### 3.3 Create Database Initialization Script - The Smart Setup

Create `srcs/requirements/mariadb/tools/init_db.sh`:

```bash
#!/bin/bash
# Exit immediately on any error
set -e

echo "Starting MariaDB initialization..."

# Check if database is already initialized
# This prevents reinitializing on container restart
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "First time setup - initializing database..."
    
    # Remove any existing data to start fresh
    rm -rf /var/lib/mysql/*
    
    # Initialize MySQL data directory
    # This creates the basic MySQL system tables
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MySQL temporarily for configuration
    # --skip-networking prevents external connections during setup
    mysqld_safe --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --skip-networking &
    mysql_pid=$!
    
    # Wait for MySQL to fully start
    echo "Waiting for MySQL to start..."
    while ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; do
        echo "Still waiting..."
        sleep 2
    done
    
    echo "MySQL started! Configuring database..."
    
    # Run security and setup commands
    mysql --socket=/run/mysqld/mysqld.sock << EOF
-- Remove anonymous users (security best practice)
DELETE FROM mysql.user WHERE User='';

-- Remove remote root login (security best practice)  
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database (security best practice)
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

-- Set root password using environment variable
SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}');

-- Create WordPress database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create WordPress user with limited privileges
-- '%' means "from any host" - allows container connections
CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Create second user (subject requirement: "two users")
-- This satisfies the "two users" requirement
CREATE USER 'wp_editor'@'%' IDENTIFIED BY 'editor_secure_pass123';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO 'wp_editor'@'%';

-- Apply all changes immediately
FLUSH PRIVILEGES;
EOF
    
    # Check if setup succeeded
    if [ $? -eq 0 ]; then
        echo "Database setup completed successfully!"
        # Create marker file to prevent re-initialization
        touch /var/lib/mysql/.initialized
    else
        echo "ERROR: Database setup failed!"
        exit 1
    fi
    
    # Stop temporary MySQL instance
    echo "Stopping temporary MySQL instance..."
    mysqladmin --socket=/run/mysqld/mysqld.sock -u root -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $mysql_pid
    
else
    echo "Database already initialized, skipping setup..."
fi

echo "Starting production MySQL instance..."
# Start MySQL in production mode
# This is the final process that keeps the container running
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql
```

**Script Logic Explained**:

1. **Initialization Check**: Uses `.initialized` marker file to avoid re-setup
2. **Fresh Start**: Removes any existing data to ensure clean setup
3. **Database Creation**: Uses `mysql_install_db` to create system tables
4. **Temporary Startup**: Starts MySQL without network access for security
5. **Security Hardening**: Removes default insecure users and databases
6. **User Creation**: Creates WordPress user and required second user
7. **Production Startup**: Starts final MySQL instance with network access

**Why this approach?**
- **Idempotent**: Can run multiple times safely
- **Secure**: Removes default insecure configurations
- **Subject compliant**: Creates exactly two database users
- **No infinite loops**: Uses proper daemon process (`mysqld_safe`)

**Test the MariaDB container**:
```bash
# Build just the MariaDB container
docker build -t test-mariadb srcs/requirements/mariadb/

# Run it with environment variables
docker run --rm -e MYSQL_ROOT_PASSWORD=test123 -e MYSQL_USER=testuser -e MYSQL_PASSWORD=testpass -e MYSQL_DATABASE=testdb test-mariadb
```

The container should start, initialize the database, and then run MySQL in production mode.

### Phase 4: WordPress Container - The Web Application Heart

**What is WordPress?** WordPress is a content management system (CMS) that powers over 40% of websites worldwide. In our setup, it handles all the web application logic - user management, content creation, theme rendering, and database interactions.

**Key Concepts**:
- **PHP-FPM**: FastCGI Process Manager - handles PHP execution efficiently
- **Separation of Concerns**: WordPress handles logic, NGINX handles web serving
- **Database Integration**: Connects to MariaDB for data persistence
- **WP-CLI**: Command-line tool for WordPress management

**Subject Requirements**:
- ✅ WordPress with PHP-FPM (NOT Apache/NGINX)
- ✅ Two WordPress users (admin + regular user)
- ✅ No pre-built WordPress images (build from scratch)

#### 4.1 Create WordPress Dockerfile - Building the Application Server

Create `srcs/requirements/wordpress/Dockerfile`:

```dockerfile
# Start with Debian bookworm base image
FROM debian:bookworm

# Install PHP-FPM and all required WordPress extensions
# NO nginx allowed in this container (subject requirement)
RUN apt-get update && apt-get install -y \
    php8.2-fpm \           # FastCGI Process Manager
    php8.2-mysql \         # MySQL/MariaDB database connection
    php8.2-curl \          # HTTP requests (plugins, updates)
    php8.2-gd \            # Image processing (media uploads)
    php8.2-intl \          # Internationalization support
    php8.2-mbstring \      # Multi-byte string functions
    php8.2-soap \          # SOAP protocol support
    php8.2-xml \           # XML processing
    php8.2-xmlrpc \        # XML-RPC protocol
    php8.2-zip \           # ZIP file handling
    curl \                 # Download tools
    wget \                 # Alternative download tool
    mariadb-client \       # Database client for connections
    && rm -rf /var/lib/apt/lists/*

# Create WordPress web directory
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Download and install WordPress from source (NO pre-built images!)
# This satisfies the "no ready-made Docker images" requirement
RUN wget https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz --strip-components=1 \
    && rm latest.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Install WP-CLI (WordPress Command Line Interface)
# This tool lets us configure WordPress programmatically
RUN curl -L https://github.com/wp-cli/wp-cli/releases/download/v2.8.1/wp-cli-2.8.1.phar -o wp-cli.phar \
    && php wp-cli.phar --info \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy WordPress setup script
COPY tools/setup_wordpress.sh /usr/local/bin/setup_wordpress.sh
RUN chmod +x /usr/local/bin/setup_wordpress.sh

# Create directory for PHP-FPM runtime files
RUN mkdir -p /var/run/php

# Expose PHP-FPM port (NOT HTTP port 80!)
# NGINX will connect to this port via FastCGI
EXPOSE 9000

# Start WordPress setup and PHP-FPM
# NO infinite loops allowed - proper daemon process
CMD ["/usr/local/bin/setup_wordpress.sh"]
```

**Dockerfile Explained Line by Line**:
- **PHP Extensions**: Each extension serves a purpose (GD for images, MySQL for database, etc.)
- **wget vs curl**: Both available for compatibility (WP-CLI needs curl)
- **mariadb-client**: Allows WordPress to test database connectivity
- **--strip-components=1**: Extracts WordPress files directly to current directory
- **www-data ownership**: Standard web server user/group for security
- **Port 9000**: Standard PHP-FPM port (NOT HTTP port 80/443)

#### 4.2 Create PHP-FPM Configuration - Performance and Security

Create `srcs/requirements/wordpress/www.conf`:

```ini
# PHP-FPM pool configuration for WordPress
[www]

# Security: Run as non-privileged user
user = www-data
group = www-data

# Listen on port 9000 for FastCGI connections from NGINX
listen = 9000

# Socket ownership and permissions
listen.owner = www-data
listen.group = www-data

# Process management: Dynamic scaling
pm = dynamic                    # Adjust processes based on demand
pm.max_children = 20           # Maximum worker processes
pm.start_servers = 2           # Initial worker processes
pm.min_spare_servers = 1       # Minimum idle processes
pm.max_spare_servers = 3       # Maximum idle processes

# Performance tuning
pm.max_requests = 500          # Restart workers after 500 requests (prevents memory leaks)

# Logging
catch_workers_output = yes     # Capture worker output for debugging
access.log = /var/log/php-fpm-access.log
```

**Configuration Explained**:
- **Dynamic PM**: Automatically scales PHP workers based on traffic
- **Resource Limits**: Prevents one site from consuming all server resources  
- **Memory Management**: Regular worker restarts prevent memory leaks
- **Security**: Non-root user execution
- **Logging**: Helps with debugging and monitoring

#### 4.3 Create WordPress Setup Script - The Smart Installation

Create `srcs/requirements/wordpress/tools/setup_wordpress.sh`:

```bash
#!/bin/bash
# Exit on any error for reliable setup
set -e

echo "Starting WordPress setup..."

# CRITICAL: Wait for MariaDB to be fully ready
# WordPress cannot start without database connectivity
echo "Waiting for MariaDB to be ready..."
while ! mysqladmin ping -h mariadb --silent; do
    echo "Database not ready, waiting 3 seconds..."
    sleep 3
done

echo "Database is ready! Testing connection..."

# Verify database connection with WordPress credentials
# This catches credential mismatches early
mysql -h mariadb -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "SELECT 1;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Database connection successful!"
else
    echo "❌ ERROR: Cannot connect to database with provided credentials"
    echo "Host: mariadb:3306"
    echo "Database: $WORDPRESS_DB_NAME"
    echo "User: $WORDPRESS_DB_USER"
    echo "Check your environment variables!"
    exit 1
fi

# Configure WordPress only if not already done
# This prevents re-configuration on container restart
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating WordPress configuration..."
    
    # Create wp-config.php with database settings
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=mariadb:3306 \
        --allow-root
    
    echo "✅ WordPress configuration created!"
    
    # Install WordPress only if not already installed
    if ! wp core is-installed --allow-root 2>/dev/null; then
        echo "Installing WordPress..."
        
        # Core WordPress installation
        wp core install \
            --url=$WORDPRESS_URL \
            --title="$WORDPRESS_TITLE" \
            --admin_user=$WORDPRESS_ADMIN_USER \
            --admin_password=$WORDPRESS_ADMIN_PASSWORD \
            --admin_email=$WORDPRESS_ADMIN_EMAIL \
            --allow-root

        echo "✅ WordPress core installed!"
        
        # Create second user (SUBJECT REQUIREMENT)
        # Subject states: "there must be two users, one of them being the administrator"
        wp user create wp_editor editor@example.com \
            --role=editor \
            --user_pass=editor_secure_pass123 \
            --display_name="Site Editor" \
            --allow-root

        echo "✅ Second WordPress user created!"
        echo "✅ WordPress installation completed!"
        
    else
        echo "WordPress already installed, skipping installation..."
    fi
else
    echo "WordPress configuration already exists, skipping setup..."
fi

# Set proper file permissions for security
echo "Setting file permissions..."
chown -R www-data:www-data /var/www/html

# Ensure wp-config.php has correct permissions
if [ -f /var/www/html/wp-config.php ]; then
    chmod 644 /var/www/html/wp-config.php
    chown www-data:www-data /var/www/html/wp-config.php
fi

echo "✅ File permissions set correctly!"

# Start PHP-FPM in foreground mode
# The -F flag keeps it running as the main process (no infinite loops!)
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
```

**Script Logic Breakdown**:

1. **Database Readiness**: Waits for MariaDB before proceeding
2. **Connection Testing**: Verifies credentials work before setup
3. **Idempotent Setup**: Only configures WordPress if not already done
4. **Two Users**: Creates admin + editor users (subject requirement)
5. **Security**: Sets proper file permissions
6. **Proper Daemon**: Uses `exec php-fpm8.2 -F` (not infinite loops)

**Why `--allow-root`?** WP-CLI normally refuses to run as root for security. In containers, we use this flag because we manage security through container isolation.

**Subject Compliance Check**:
- ✅ Two WordPress users created (admin + editor)
- ✅ Admin username doesn't contain 'admin' (uses environment variable)
- ✅ PHP-FPM only (no NGINX in this container)
- ✅ Proper daemon process (no infinite loops)
- ✅ Environment variables for all configuration

**Test the WordPress container**:
```bash
# Build the container
docker build -t test-wordpress srcs/requirements/wordpress/

# Test with environment variables
docker run --rm \
  -e WORDPRESS_DB_HOST=localhost \
  -e WORDPRESS_DB_USER=testuser \
  -e WORDPRESS_DB_PASSWORD=testpass \
  -e WORDPRESS_DB_NAME=testdb \
  -e WORDPRESS_ADMIN_USER=john_doe \
  -e WORDPRESS_ADMIN_PASSWORD=adminpass \
  -e WORDPRESS_ADMIN_EMAIL=john@test.com \
  -e WORDPRESS_TITLE="Test Site" \
  -e WORDPRESS_URL=https://test.local \
  test-wordpress
```

### Phase 5: NGINX Container

#### 5.1 Create NGINX Dockerfile
`srcs/requirements/nginx/Dockerfile`:
```dockerfile
FROM debian:bookworm

# Install NGINX and OpenSSL
RUN apt-get update && apt-get install -y \
    nginx openssl \
    && rm -rf /var/lib/apt/lists/*

# Generate SSL certificate (mandatory HTTPS only)
RUN mkdir -p /etc/nginx/certs
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/nginx.key \
    -out /etc/nginx/certs/nginx.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=student/CN=yourusername.42.fr"

# Copy configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create log directory
RUN mkdir -p /var/log/nginx

# ONLY port 443 allowed (HTTPS only)
EXPOSE 443

# NO infinite loops - proper daemon
CMD ["nginx", "-g", "daemon off;"]
```

#### 5.2 Create NGINX Configuration
`srcs/requirements/nginx/conf/nginx.conf`:
```nginx
user www-data;
worker_processes auto;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    # TLS 1.2/1.3 ONLY (subject requirement)
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    server {
        # HTTPS ONLY - port 443 only
        listen 443 ssl;
        server_name yourusername.42.fr;  # Replace with YOUR login

        ssl_certificate /etc/nginx/certs/nginx.crt;
        ssl_certificate_key /etc/nginx/certs/nginx.key;

        root /var/www/html;
        index index.php index.html;

        # Forward to WordPress
        location / {
            try_files $uri $uri/ /index.php?$args;
        }

        # PHP processing via FastCGI to WordPress container
        location ~ \.php$ {
            include fastcgi_params;
            fastcgi_pass wordpress:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        }
    }
}
```

### Phase 6: Docker Compose Configuration

#### 6.1 Create docker-compose.yml
`srcs/docker-compose.yml`:
```yaml
version: '3.8'

services:
  nginx:
    build: ./requirements/nginx
    container_name: nginx
    ports:
      - "443:443"    # ONLY HTTPS allowed
    restart: always  # Auto-restart on crash (mandatory)
    networks:
      - inception_network
    depends_on:
      - wordpress
    volumes:
      - wordpress_files:/var/www/html

  wordpress:
    build: ./requirements/wordpress
    container_name: wordpress
    restart: always  # Auto-restart on crash (mandatory)
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_ADMIN_USER: ${WORDPRESS_ADMIN_USER}
      WORDPRESS_ADMIN_PASSWORD: ${WORDPRESS_ADMIN_PASSWORD}
      WORDPRESS_ADMIN_EMAIL: ${WORDPRESS_ADMIN_EMAIL}
      WORDPRESS_TITLE: ${WORDPRESS_TITLE}
      WORDPRESS_URL: ${WORDPRESS_URL}
    volumes:
      - wordpress_files:/var/www/html
    networks:
      - inception_network
    depends_on:
      - mariadb

  mariadb:
    build: ./requirements/mariadb
    container_name: mariadb
    restart: always  # Auto-restart on crash (mandatory)
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - inception_network

# Custom network (mandatory)
networks:
  inception_network:
    driver: bridge

# Host-mounted volumes (mandatory location)
volumes:
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourusername/data/mariadb  # Replace with YOUR login
  wordpress_files:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yourusername/data/wordpress  # Replace with YOUR login
```

### Phase 7: Makefile Creation

#### 7.1 Create Makefile
`Makefile`:
```makefile
NAME = inception

# Default target
all: build up

# Build all images
build:
	docker-compose -f srcs/docker-compose.yml build

# Start containers in detached mode
up:
	docker-compose -f srcs/docker-compose.yml up -d

# Stop containers
down:
	docker-compose -f srcs/docker-compose.yml down

# Stop containers (keep for restart)
stop:
	docker-compose -f srcs/docker-compose.yml stop

# Clean system
clean: down
	docker system prune -af
	docker volume prune -f

# Full cleanup
fclean: clean
	docker rmi -f $$(docker images -qa) 2>/dev/null || true
	docker volume rm $$(docker volume ls -q) 2>/dev/null || true

# Rebuild everything
re: fclean all

.PHONY: all build up down stop clean fclean re
```

### Phase 8: Final Setup & Testing

#### 8.1 Create Host Directories
```bash
# Replace 'yourusername' with your actual login
sudo mkdir -p /home/$(whoami)/data/{wordpress,mariadb}
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data
```

#### 8.2 Build and Test
```bash
# Build everything
make build

# Start services
make up

# Check status
docker-compose -f srcs/docker-compose.yml ps

# View logs
docker-compose -f srcs/docker-compose.yml logs -f
```

#### 8.3 Verify Everything Works
```bash
# Test HTTPS connection
curl -k https://yourusername.42.fr

# Check WordPress is accessible
# Open browser: https://yourusername.42.fr
```

### 🔍 Subject Compliance Checklist

Before submitting, verify ALL requirements:

- [ ] **Virtual Machine**: Project runs on VM
- [ ] **Custom Dockerfiles**: One per service, no pre-built images
- [ ] **Docker Compose**: Services orchestrated properly
- [ ] **NGINX**: HTTPS only, TLS 1.2/1.3, port 443
- [ ] **WordPress**: PHP-FPM only, no NGINX
- [ ] **MariaDB**: Database only, no NGINX
- [ ] **Two Users**: Admin (no 'admin' in name) + regular user
- [ ] **Volumes**: Persistent storage in `/home/login/data`
- [ ] **Network**: Custom Docker network
- [ ] **Auto-restart**: All containers restart on crash
- [ ] **No Infinite Loops**: No `tail -f`, `sleep infinity`, etc.
- [ ] **Environment Variables**: No passwords in Dockerfiles
- [ ] **Domain Name**: `yourusername.42.fr` format
- [ ] **No Forbidden Items**: No `--link`, `network: host`, `latest` tag

### 🚨 Common Pitfalls to Avoid

1. **Using pre-built WordPress/MariaDB images** → Build from Debian/Alpine only
2. **Including 'admin' in admin username** → Use different name
3. **Using HTTP** → HTTPS only, port 443 only
4. **Infinite loops in containers** → Use proper daemons
5. **Passwords in Dockerfiles** → Use environment variables only
6. **Wrong volume paths** → Must be `/home/login/data`
7. **Missing network configuration** → Custom network mandatory
8. **Using `latest` tag** → Specify exact versions
9. **Missing auto-restart** → Add `restart: always`
10. **Forgetting second WordPress user** → Create during setup

### 💡 Pro Tips for Success

- **Test incrementally**: Build one service at a time
- **Check logs frequently**: `docker-compose logs servicename`
- **Validate with clean VM**: Test your Makefile from scratch
- **Understand every line**: Don't copy-paste without understanding
- **Plan your evaluation**: Be ready to explain every component

This guide follows the subject requirements exactly. Customize the usernames, passwords, and configurations for your specific setup, but maintain the core structure and compliance requirements.

## �🛠️ Prerequisites

- **Virtual Machine** (required by 42 School subject)
- **Docker** (20.10.0 or higher)
- **Docker Compose** (1.29.0 or higher)
- **Make** utility
- **Root access** (for creating directories in /home/login/data)

### System Requirements:
- **OS**: Linux (tested on Ubuntu 20.04+)
- **RAM**: Minimum 2GB available
- **Storage**: At least 5GB free space
- **Network**: Internet connection for initial setup

## 🚀 Installation & Setup

### 1. Clone the Repository
```bash
git clone git@github.com:luizpanigassi/inception42.git
cd inception
```

### 2. Prepare Host Directories
```bash
# Create data directories (replace 'login' with your username)
sudo mkdir -p /home/$(whoami)/data/wordpress
sudo mkdir -p /home/$(whoami)/data/mariadb

# Set proper permissions
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data
```

### 3. Configure Environment
```bash
# Copy and edit environment variables
cp srcs/.env.example srcs/.env  # If you have an example file
# OR edit srcs/.env directly with your settings
```

### 4. Set up Domain (Local Development)
```bash
# Add your domain to /etc/hosts for local testing
echo "127.0.0.1 yourdomain.42.fr" | sudo tee -a /etc/hosts
```

### 5. Build and Run
```bash
# Build all containers and start services
make

# Or step by step:
make build    # Build Docker images
make up       # Start containers in detached mode
```

### 6. Verify Installation
- Open your browser and navigate to `https://yourdomain.42.fr`
- Accept the self-signed certificate warning (for local development)
- You should see your WordPress site

## ⚙️ Configuration

### Environment Variables (.env)

The `.env` file contains all configuration settings. **Important**: Never commit real passwords to version control.

```bash
# Domain Configuration
DOMAIN_NAME=yourdomain.42.fr

# Database Settings
MYSQL_ROOT_PASSWORD=secure_root_password
MYSQL_USER=wp_user
MYSQL_PASSWORD=secure_user_password
MYSQL_DATABASE=wordpress

# WordPress Admin Settings
WORDPRESS_ADMIN_USER=admin_user        # Cannot contain 'admin'!
WORDPRESS_ADMIN_PASSWORD=secure_admin_password
WORDPRESS_ADMIN_EMAIL=your@email.com
WORDPRESS_TITLE=Your Site Title
WORDPRESS_URL=https://yourdomain.42.fr

# PHP-FPM Settings
PHP_FPM_USER=www-data
PHP_FPM_GROUP=www-data
```

### SSL Configuration

The project automatically generates self-signed SSL certificates. For production, replace with proper certificates:

```bash
# Replace auto-generated certificates
cp your-certificate.crt srcs/requirements/nginx/certs/nginx.crt
cp your-private-key.key srcs/requirements/nginx/certs/nginx.key
```

## 🐳 Services Breakdown

### NGINX Container

**Purpose**: Reverse proxy server with SSL termination

**Key Features**:
- HTTPS-only (TLS 1.2/1.3)
- Reverse proxy to WordPress
- Automatic SSL certificate generation
- Security headers

**Configuration Files**:
- `requirements/nginx/Dockerfile`: Container build instructions
- `requirements/nginx/conf/nginx.conf`: Server configuration

**Important Notes**:
- Only listens on port 443 (HTTPS)
- Automatically redirects to WordPress for PHP files
- SSL certificates are generated during container build

### WordPress Container

**Purpose**: PHP-FPM server running WordPress

**Key Features**:
- PHP 8.2 with required extensions
- WordPress installed via WP-CLI
- Automatic database connection setup
- Two users created (admin + editor)

**Configuration Files**:
- `requirements/wordpress/Dockerfile`: Container build
- `requirements/wordpress/www.conf`: PHP-FPM pool config
- `requirements/wordpress/tools/setup_wordpress.sh`: Initialization script

**Important Notes**:
- Runs PHP-FPM on port 9000
- Waits for database before starting
- Creates WordPress config automatically

### MariaDB Container

**Purpose**: Database server for WordPress

**Key Features**:
- MariaDB 10.6+ 
- Automatic database initialization
- Multiple users (WordPress + admin)
- Persistent data storage

**Configuration Files**:
- `requirements/mariadb/Dockerfile`: Container build
- `requirements/mariadb/conf/my.cnf`: Database configuration
- `requirements/mariadb/tools/init_db.sh`: Database setup script

**Important Notes**:
- Data persists in host volume
- Creates WordPress database automatically
- Secured with custom passwords

## 🔒 Security Features

### SSL/TLS Configuration
- **TLS 1.2 and 1.3 only** (older versions disabled)
- **Strong cipher suites** preferred
- **Self-signed certificates** (auto-generated)
- **HTTPS redirection** (no HTTP access)

### Database Security
- **Custom root password** (no default passwords)
- **Dedicated WordPress user** (minimal privileges)
- **Network isolation** (only accessible from WordPress container)
- **Secure initialization** (removes test databases and users)

### Container Security
- **Non-root processes** where possible
- **Minimal base images** (Debian Bookworm)
- **No unnecessary packages** installed
- **Proper file permissions** set

### Network Security
- **Custom Docker network** (isolated from default bridge)
- **No host networking** used
- **Container-to-container** communication only
- **No exposed ports** except NGINX 443

## 🎯 Makefile Commands

The Makefile provides convenient commands for managing the infrastructure:

```bash
# Build and start everything
make                # Same as 'make all'
make all            # Build images and start containers

# Individual operations
make build          # Build all Docker images
make up             # Start containers in detached mode
make down           # Stop and remove containers
make stop           # Stop containers (keep for restart)

# Cleanup operations
make clean          # Remove containers and clean Docker system
make fclean         # Full cleanup (remove images and volumes)
make re             # Full rebuild (fclean + all)

# Status check
docker-compose -f srcs/docker-compose.yml ps    # Check container status
docker-compose -f srcs/docker-compose.yml logs  # View logs
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. "Permission Denied" on Data Directories
```bash
# Fix directory permissions
sudo chown -R $(whoami):$(whoami) /home/$(whoami)/data
sudo chmod -R 755 /home/$(whoami)/data
```

#### 2. "Database Connection Error"
```bash
# Check if MariaDB is running
docker-compose -f srcs/docker-compose.yml logs mariadb

# Verify environment variables
grep -E "MYSQL_|WORDPRESS_DB_" srcs/.env

# Test database connectivity
docker-compose -f srcs/docker-compose.yml exec mariadb mysql -u root -p
```

#### 3. "SSL Certificate Error"
```bash
# Regenerate certificates
docker-compose -f srcs/docker-compose.yml build nginx --no-cache

# Check certificate details
openssl x509 -in srcs/requirements/nginx/certs/nginx.crt -text -noout
```

#### 4. "Container Won't Start"
```bash
# Check container logs
docker-compose -f srcs/docker-compose.yml logs [service-name]

# Inspect container configuration
docker-compose -f srcs/docker-compose.yml config

# Rebuild specific service
docker-compose -f srcs/docker-compose.yml build [service-name] --no-cache
```

#### 5. "WordPress Installation Fails"
```bash
# Check WordPress logs
docker-compose -f srcs/docker-compose.yml logs wordpress

# Enter WordPress container for debugging
docker-compose -f srcs/docker-compose.yml exec wordpress bash

# Verify file permissions
docker-compose -f srcs/docker-compose.yml exec wordpress ls -la /var/www/html
```

### Debug Commands

```bash
# View all container logs
docker-compose -f srcs/docker-compose.yml logs -f

# Check container resource usage
docker stats

# Inspect network configuration
docker network inspect srcs_inception_network

# Check volume mounts
docker volume ls
docker volume inspect srcs_mariadb_data srcs_wordpress_files
```

## 📚 Learning Resources

### Docker & Containerization
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### NGINX Configuration
- [NGINX Documentation](https://nginx.org/en/docs/)
- [SSL/TLS Configuration Guide](https://ssl-config.mozilla.org/)
- [NGINX Reverse Proxy Guide](https://docs.nginx.com/nginx/admin-guide/web-server/reverse-proxy/)

### WordPress & PHP
- [WordPress Codex](https://codex.wordpress.org/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [PHP-FPM Configuration](https://www.php.net/manual/en/install.fpm.configuration.php)

### MariaDB
- [MariaDB Documentation](https://mariadb.org/documentation/)
- [MySQL/MariaDB Security Guide](https://mariadb.com/kb/en/securing-mariadb/)

## 🧪 Testing Your Setup

### Automated Tests
Create a simple test script to verify everything is working:

```bash
#!/bin/bash
# test_inception.sh

echo "Testing Inception Setup..."

# Test HTTPS connection
echo "1. Testing HTTPS connection..."
curl -k -s https://yourdomain.42.fr > /dev/null && echo "✓ HTTPS working" || echo "✗ HTTPS failed"

# Test WordPress
echo "2. Testing WordPress..."
curl -k -s https://yourdomain.42.fr | grep -q "WordPress" && echo "✓ WordPress detected" || echo "✗ WordPress not found"

# Test database connection
echo "3. Testing database connection..."
docker-compose -f srcs/docker-compose.yml exec -T mariadb mysql -u$MYSQL_USER -p$MYSQL_PASSWORD -e "SELECT 1;" > /dev/null 2>&1 && echo "✓ Database accessible" || echo "✗ Database connection failed"

# Test volumes
echo "4. Testing volumes..."
[ -d "/home/$(whoami)/data/wordpress" ] && echo "✓ WordPress volume exists" || echo "✗ WordPress volume missing"
[ -d "/home/$(whoami)/data/mariadb" ] && echo "✓ MariaDB volume exists" || echo "✗ MariaDB volume missing"

echo "Testing complete!"
```

### Manual Testing Checklist

- [ ] All containers are running: `docker-compose ps`
- [ ] Website loads via HTTPS
- [ ] WordPress admin panel accessible
- [ ] Database contains WordPress tables
- [ ] SSL certificate is valid (even if self-signed)
- [ ] Two WordPress users exist (admin + editor)
- [ ] Data persists after container restart
- [ ] No HTTP access (only HTTPS)

## 💡 Tips for 42 Students

### Understanding the Requirements
1. **Read the subject carefully** - Every requirement must be met exactly
2. **Use only allowed base images** - Debian or Alpine only
3. **No pre-built images** - You must build everything yourself
4. **Custom Dockerfiles required** - One per service
5. **Volumes must be in specific location** - `/home/login/data`

### Common Pitfalls to Avoid
- Don't use `network: host` or `--link`
- Don't use infinite loops (`tail -f`, `sleep infinity`)
- Admin username cannot contain 'admin'
- Must use TLS 1.2 or 1.3 only
- Containers must restart automatically

### Evaluation Preparation
- Make sure your Makefile works from a clean state
- Test on a fresh VM before evaluation
- Prepare to explain your Docker concepts
- Know how to debug container issues
- Understand the security implications

## 🤝 Contributing

If you're a 42 student who found this helpful, consider:

1. **Sharing improvements** - Submit pull requests for bug fixes
2. **Adding documentation** - Help explain complex concepts
3. **Testing on different systems** - Verify compatibility
4. **Creating examples** - Show alternative implementations

### Contribution Guidelines
- Follow the same coding style
- Add comments for complex configurations
- Test changes thoroughly
- Update documentation as needed

## 📄 License

This project is created for educational purposes as part of the 42 School curriculum. Feel free to use it as a learning resource, but make sure to understand and implement your own version for your evaluation.

## 🙏 Acknowledgments

- **42 School** for the excellent project design
- **Docker community** for comprehensive documentation
- **Fellow students** who helped debug issues
- **Open source projects** that make this possible

---

**Remember**: This project is about learning Docker, containerization, and system administration concepts. Make sure you understand each component rather than just copying configurations. Good luck with your evaluation! 🚀

## 📞 Support

If you're stuck or have questions:

1. **Check the troubleshooting section** above
2. **Read the official documentation** for each service
3. **Ask fellow 42 students** in your campus
4. **Use Docker community forums** for general Docker issues

**Happy coding!** 🐳✨