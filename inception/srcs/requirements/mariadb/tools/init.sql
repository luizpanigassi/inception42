CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'shadow_admin'@'%' IDENTIFIED BY 'senha_segura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'shadow_admin'@'%';
CREATE_USER IF NOT EXISTS 'tonto_user'@'%' IDENTIFIED BY 'outra_senha';
GRANT SELECT, INSERT, UPDATE ON wordpress.* TO 'tonto_user'@'%';
FLUSH PRIVILEGES;
