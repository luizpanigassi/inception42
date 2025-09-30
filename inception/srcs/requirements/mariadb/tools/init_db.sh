#!/bin/bash

# Start MariaDB in the background
mysqld_safe --datadir='/var/lib/mysql' &

# Wait for MariaDB to start
sleep 10

# Run the initialization SQL script
mysql -u root < /docker-entrypoint-initdb.d/init.sql

# Stop MariaDB
mysqladmin -u root -p$MYSQL_ROOT_PASSWORD shutdown

# Start MariaDB in the foreground
exec mysqld_safe --datadir='/var/lib/mysql'
