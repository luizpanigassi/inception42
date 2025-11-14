#!/bin/bash
set -e

echo "Starting WordPress setup..."

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb --silent; do
    echo "MariaDB not ready, waiting..."
    sleep 3
done

echo "MariaDB is ready!"

# Test database connection with our credentials
echo "Testing database connection..."
mysql -h mariadb -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD -e "SELECT 1;" > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "Database connection successful!"
else
    echo "ERROR: Cannot connect to database with provided credentials"
    echo "Host: $WORDPRESS_DB_HOST"
    echo "Database: $WORDPRESS_DB_NAME"
    echo "User: $WORDPRESS_DB_USER"
    exit 1
fi

# Check if WordPress is already configured
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Creating WordPress configuration..."
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --allow-root
    
    echo "WordPress configuration created!"
    
    # Install WordPress if not already done
    if ! wp core is-installed --allow-root 2>/dev/null; then
        echo "Installing WordPress..."
        wp core install \
            --url=$WORDPRESS_URL \
            --title="$WORDPRESS_TITLE" \
            --admin_user=$WORDPRESS_ADMIN_USER \
            --admin_password=$WORDPRESS_ADMIN_PASSWORD \
            --admin_email=$WORDPRESS_ADMIN_EMAIL \
            --allow-root

        # Create a second user (as required by the subject)
        wp user create second_user second@example.com \
            --role=editor \
            --user_pass=second_pass123 \
            --allow-root

        echo "WordPress installation completed!"
    else
        echo "WordPress already installed."
    fi
else
    echo "WordPress already configured."
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html

# Ensure wp-config.php has correct permissions
if [ -f /var/www/html/wp-config.php ]; then
    chmod 644 /var/www/html/wp-config.php
    chown www-data:www-data /var/www/html/wp-config.php
fi

# Start PHP-FPM
exec php-fpm8.2 -F
