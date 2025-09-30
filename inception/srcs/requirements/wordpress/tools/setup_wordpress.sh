#!/bin/bash

# Wait for MariaDB to be ready
while ! mysqladmin ping -h mariadb -u $WORDPRESS_DB_USER -p$WORDPRESS_DB_PASSWORD --silent; do
    echo "Waiting for MariaDB to be ready..."
    sleep 2
done

echo "MariaDB is ready!"

# Check if WordPress is already configured
if [ ! -f /var/www/html/wp-config.php ]; then
    echo "Configuring WordPress..."

    # Create wp-config.php
    wp config create \
        --dbname=$WORDPRESS_DB_NAME \
        --dbuser=$WORDPRESS_DB_USER \
        --dbpass=$WORDPRESS_DB_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --allow-root

    # Install WordPress
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

    echo "WordPress configured successfully!"
else
    echo "WordPress already configured."
fi

# Set proper permissions
chown -R www-data:www-data /var/www/html

# Start PHP-FPM
exec php-fpm8.2 -F
