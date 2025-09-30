FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    mariadb-server \
    && rm -rf /var/lib/apt/lists/*

# Copy MariaDB configuration
COPY conf/my.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init.sql /docker-entrypoint-initdb.d/init.sql

# Create a script to initialize the database
COPY tools/init_db.sh /usr/local/bin/init_db.sh
RUN chmod +x /usr/local/bin/init_db.sh

# Create directory for MariaDB run files
RUN mkdir -p /var/run/mysqld
RUN chown -R mysql:mysql /var/run/mysqld

# Expose port 3306
EXPOSE 3306

# Start MariaDB with initialization script
CMD ["/usr/local/bin/init_db.sh"]
