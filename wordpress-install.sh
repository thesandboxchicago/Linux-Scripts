#!/bin/bash

## Sanity Checks and automagic
function root-check() {
if [[ "$EUID" -ne 0 ]]; then
  echo "Sorry, you need to run this as root"
  exit
fi
}

## Root Check
root-check

function dist-check() {
  if [ -e /etc/debian_version ]; then
    DISTRO=$( lsb_release -is )
  else
    echo "Your distribution is not supported (yet)."
    exit
  fi
}

## Check distro
dist-check

## Start Installation Of Packages
function install-essentials() {
  if [ "$DISTRO" == "Debian" ]; then
    apt-get install nginx -y
    apt-get install php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-xmlrpc php-zip php-mysql
  fi
}

## Install Essentials
install-essentials

## Start Installation Of Wordpress
function install-wordpress() {
    rm /var/www/html/index.nginx-debian.html
    sed -i 's|index index.html index.htm index.nginx-debian.html;$|index index.html index.php;|' /etc/nginx/sites-available/default
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar xf latest.tar.gz
    sudo mv /tmp/wordpress/* /var/www/html
    rm latest.tar.gz
    rm -rf wordpress
}

## Install Wordpresss
install-wordpress

## Function for correct permission
function correct-permissions() {
cd /var/www/
chown www-data:www-data  -R *
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
}

## Run correct permissions 
correct-permissions

function mysql-install() {
    cd /tmp/
    wget http://repo.mysql.com/mysql-apt-config_0.8.14-1_all.deb
    dpkg -i mysql-apt-config_0.8.13-1_all.deb
    rm mysql-apt-config_0.8.13-1_all.deb 
    apt-get update
    apt-get install mysql-server -y
  }
    
    mysql-install

function mysql-setup() {
echo "RUN THESE COMMANDS"
echo "------------------------------------------------------------------------------------------"
echo "mysql_secure_installation"
echo "mysql -u root -p"
echo "CREATE DATABASE <WORDPRESS_DATABASE_NAME>;"
echo "CREATE USER `<WORDPRESS_DATABASE_USER>`@`localhost` IDENTIFIED BY '<WORDPRESS_DATABASE_PASSWORD>';"
echo "ALTER USER `<WORDPRESS_DATABASE_USER>`@`localhost` IDENTIFIED WITH mysql_native_password BY '<WORDPRESS_DATABASE_PASSWORD>';"
echo "GRANT ALL ON <WORDPRESS_DATABASE_NAME>.* TO `<WORDPRESS_DATABASE_USER>`@`localhost`;"
echo "FLUSH PRIVILEGES;"
echo "exit"
echo "------------------------------------------------------------------------------------------"
}

# Run SQL Setup
mysql-setup


function lets-encrypt() {
  sudo apt-get install certbot python-certbot-nginx -y
  sudo certbot --nginx
  sudo certbot renew --dry-run
}

lets-encrypt
