FROM debian:bookworm
RUN apt-get update && apt-get install -y mariadb-server
COPY conf/my.cnf /etc/mysql/my.cnf
CMD ["mysqld"]
COPY tools/init.sql /docker-entrypoint-initdb.d/
