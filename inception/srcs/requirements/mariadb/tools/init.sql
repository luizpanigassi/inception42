-- Set root password
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';

-- Create database
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

-- Create WordPress user
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';

-- Create admin user (not containing 'admin' in name as per requirements)
CREATE USER IF NOT EXISTS 'shadow_user'@'%' IDENTIFIED BY 'shadow_pass123';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO 'shadow_user'@'%';

-- Flush privileges
FLUSH PRIVILEGES;
