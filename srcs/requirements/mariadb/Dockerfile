FROM debian:bookworm

# Fix repository configuration to avoid date validation issues
RUN rm -rf /etc/apt/sources.list.d/* \
    && echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list \
    && apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy MariaDB configuration
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init.sql /docker-entrypoint-initdb.d/init.sql

# Create a script to initialize the database
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Create and set proper permissions for directories
RUN mkdir -p /run/mysqld /var/lib/mysql
RUN chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Expose port 3306
EXPOSE 3306

# Start MariaDB with initialization script
CMD ["/usr/local/bin/init_db.sh"]
