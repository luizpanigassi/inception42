FROM debian:bookworm
RUN apt-get update && apt-get install -y php-fpm php-mysql
COPY conf/www.conf /etc/php/7.4/fpm/pool.d/www.conf
CMD ["php-fpm7.4", "-F"]
