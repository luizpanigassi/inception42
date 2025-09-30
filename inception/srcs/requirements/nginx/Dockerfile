FROM debian:bookworm
RUN apt-get update && apt-get install -y nginx openssl
COPY conf/nginx.conf /etc/nginx/nginx.conf
CMD ["nginx", "-g", "daemon off;"]
