#!/bin/bash
set -e

echo "MariaDB initialization starting..."

# Check if we need to initialize
if [ ! -f "/var/lib/mysql/.initialized" ]; then
    echo "First time setup - initializing database..."
    
    # Remove any existing data
    rm -rf /var/lib/mysql/*
    
    # Initialize MySQL data directory
    mysql_install_db --user=mysql --datadir=/var/lib/mysql
    
    # Start MySQL temporarily for setup
    mysqld_safe --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock --skip-networking &
    mysql_pid=$!
    
    # Wait for MySQL to start
    echo "Waiting for MySQL to start..."
    for i in {1..30}; do
        if mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; then
            echo "MySQL is ready!"
            break
        fi
        echo "Waiting... ($i/30)"
        sleep 2
    done
    
    # Verify MySQL is running
    if ! mysqladmin ping --socket=/run/mysqld/mysqld.sock --silent; then
        echo "ERROR: Could not connect to MySQL"
        exit 1
    fi
    
    echo "Setting up database and users..."
    
    # Run setup commands
    mysql --socket=/run/mysqld/mysqld.sock << EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';

SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MYSQL_ROOT_PASSWORD}');

CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

CREATE USER 'shadow_user'@'%' IDENTIFIED BY 'shadow_pass123';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO 'shadow_user'@'%';

FLUSH PRIVILEGES;
EOF
    
    if [ $? -eq 0 ]; then
        echo "Database setup completed successfully!"
        touch /var/lib/mysql/.initialized
    else
        echo "ERROR: Database setup failed"
        exit 1
    fi
    
    # Stop the temporary MySQL instance
    mysqladmin --socket=/run/mysqld/mysqld.sock -uroot -p"${MYSQL_ROOT_PASSWORD}" shutdown
    wait $mysql_pid
    
    echo "Temporary MySQL stopped, starting production instance..."
else
    echo "Database already initialized, starting MySQL..."
fi

# Start MySQL in production mode
exec mysqld_safe --user=mysql --datadir=/var/lib/mysql --socket=/run/mysqld/mysqld.sock
