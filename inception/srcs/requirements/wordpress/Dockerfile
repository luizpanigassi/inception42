FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-curl \
    php8.2-gd \
    php8.2-intl \
    php8.2-mbstring \
    php8.2-soap \
    php8.2-xml \
    php8.2-xmlrpc \
    php8.2-zip \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Create WordPress directory
RUN mkdir -p /var/www/html
WORKDIR /var/www/html

# Download and install WordPress
RUN wget https://wordpress.org/latest.tar.gz \
    && tar -xzf latest.tar.gz --strip-components=1 \
    && rm latest.tar.gz \
    && chown -R www-data:www-data /var/www/html

# Download WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

# Copy PHP-FPM configuration
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf

# Copy WordPress setup script
COPY tools/setup_wordpress.sh /usr/local/bin/setup_wordpress.sh
RUN chmod +x /usr/local/bin/setup_wordpress.sh

# Create directory for PHP-FPM run files
RUN mkdir -p /var/run/php

# Expose port 9000
EXPOSE 9000

# Start PHP-FPM with WordPress setup
CMD ["/usr/local/bin/setup_wordpress.sh"]
