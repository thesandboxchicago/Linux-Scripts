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
    apt-get install nginx php7.3 php-curl libapache2-mod-php php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick php-soap php-fpm php-zip php-json -y
    cd /tmp/
    wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb
    dpkg -i mysql-apt-config_0.8.13-1_all.deb
    rm mysql-apt-config_0.8.13-1_all.deb 
    apt-get update
    apt-get install mysql-server -y
  fi
}

## Install Essentials
install-essentials

## Start Installation Of Wordpress
function install-wordpress() {
    rm /var/www/html/index.html
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar xf latest.tar.gz
    sudo mv /tmp/wordpress/* /var/www/html
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
