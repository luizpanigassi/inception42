FROM debian:bookworm

# Fix repository configuration to avoid date validation issues
RUN rm -rf /etc/apt/sources.list.d/* \
    && echo "deb http://deb.debian.org/debian bookworm main" > /etc/apt/sources.list \
    && apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -rf /var/lib/apt/lists/*

# Create directory for SSL certificates
RUN mkdir -p /etc/nginx/certs

# Generate self-signed SSL certificate
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/certs/nginx.key \
    -out /etc/nginx/certs/nginx.crt \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=42SP/OU=student/CN=luinasci.42.fr"

# Copy nginx configuration
COPY conf/nginx.conf /etc/nginx/nginx.conf

# Create directory for logs
RUN mkdir -p /var/log/nginx

# Expose port 443
EXPOSE 443

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
