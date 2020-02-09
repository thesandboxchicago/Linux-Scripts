#!/bin/bash

## Sanity Checks and automagic
function root-check() {
if [ "$EUID" -ne 0 ]; then
  echo "Sorry, you need to run this as root"
  exit
fi
}

## Root Check
root-check

function dist-check() {
  if [ -e /etc/debian_version ]; then
    DISTRO=$(lsb_release -is)
  else
    echo "Your distribution is not supported (yet)."
    exit
  fi
}

# Check Operating System
dist-check

## Start Installation Of Packages
function install-essentials() {
  if [ "$DISTRO" == "Debian" ]; then
    apt-get update
    apt-get upgrade -y
    apt-get dist-upgrade -y
    apt-get install linux-headers-$(uname -r) -y
    apt-get install build-essential -y
    apt-get install nginx -y
    apt-get install redis-server -y
    apt-get install php7.3-fpm php-curl php-gd php-intl php-mbstring php-soap php-xml php-pear php-xmlrpc php-zip php-mysql php-imagick php-common php-json php-cgi php-redis -y
    ## Update
    apt-get install unattended-upgrades apt-listchanges -y
    dpkg-reconfigure unattended-upgrades
    ## Fail2Ban
    apt-get install fail2ban -y
    ## UFW
    apt-get install iptables iptables-persistent ufw -y
    ufw allow "http"
    ufw allow "https"
    ufw allow "ssh"
    ufw default deny incoming
    ufw default deny outgoing
    ufw enable
  fi
}

## Install Essentials
install-essentials

## Function to install mysql
function mysql-install() {
  if [ "$DISTRO" == "Debian" ]; then
    cd /tmp/
    wget http://repo.mysql.com/mysql-apt-config_0.8.14-1_all.deb
    dpkg -i mysql-apt-config_0.8.14-1_all.deb 
    rm mysql-apt-config_0.8.14-1_all.deb 
    apt-get update
    apt-get install mysql-server -y
  fi
  }

    ## run the function 
    mysql-install

## Function For TCP BBR
function tcp-install() {
  if [ "$DISTRO" == "Debian" ]; then
    modprobe tcp_bbr
    echo "tcp_bbr" >> /etc/modules-load.d/modules.conf
    echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf 
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    sysctl -p
    uname -r
    sysctl net.ipv4.tcp_available_congestion_control
    sysctl net.ipv4.tcp_congestion_control
    sysctl net.core.default_qdisc
    lsmod | grep bbr
  fi
}

## TCP BBR
tcp-install

## Start Installation Of Wordpress
function install-wordpress() {
  if [ "$DISTRO" == "Debian" ]; then
    rm /var/www/html/index.nginx-debian.html
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar xf latest.tar.gz
    sudo mv /tmp/wordpress/* /var/www/html
    rm latest.tar.gz
    rm -rf wordpress
    wget -O /var/www/html/wp-content/object-cache.php https://gist.githubusercontent.com/Prajwal-Koirala/3f4017183a68ce015d0146d2fb05ee68/raw/e89a4616a71eb0fd4dbc2ea5552d48212b7055c8/object-cache.php
  fi
}

## Install Wordpresss
install-wordpress

## Nginx config file
function nginx-conf() {
  rm /etc/nginx/sites-available/default
  sed -i "s|# server_tokens off;|server_tokens off;|" /etc/nginx/nginx.conf
echo "server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;

    index index.php;

    server_name _;

    location / {
      try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
      include snippets/fastcgi-php.conf;
      fastcgi_pass unix:/run/php/php7.3-fpm.sock;
    }
}" >> /etc/nginx/sites-available/default

sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/
}

## Run the function
nginx-conf

## Function for correct permission
function correct-permissions() {
service nginx restart
service php7.3-fpm restart
chown www-data:www-data  -R *
find /var/www/html -type d -exec chmod 755 {} \;
find /var/www/html -type f -exec chmod 644 {} \;
}

## Run correct permissions 
correct-permissions

function mysql-setup() {
echo "------------------------------------------------------------------------------------------"
mysql_secure_installation
mysql -u root -p
CREATE DATABASE {datbase_name};
CREATE USER `{database_user}`@`localhost` IDENTIFIED BY '{database_password}';
ALTER USER `{database_user}`@`localhost` IDENTIFIED WITH mysql_native_password BY '{database_password}';
GRANT ALL ON {datbase_name}.* TO `{database_user}`@`localhost`;
FLUSH PRIVILEGES;
exit
echo "------------------------------------------------------------------------------------------"
}

# Run SQL Setup
mysql-setup

# Installs and setups lets-encrypt 
function lets-encrypt() {
  sudo apt-get install certbot python-certbot-nginx -y
  sudo certbot --nginx
  sudo certbot renew --dry-run
}

# lets-encrypt function
lets-encrypt

function wp-conf() {
echo "/* SSL */
define( 'FORCE_SSL_LOGIN', true );
define( 'FORCE_SSL_ADMIN', true );

/* Specify maximum number of Revisions. */
define( 'WP_POST_REVISIONS', '3' );
/* Media Trash. */
define( 'MEDIA_TRASH', true );
/* Trash Days. */
define( 'EMPTY_TRASH_DAYS', '7' );

/* Multisite. */
define( 'WP_ALLOW_MULTISITE', false );

/* WordPress debug mode for developers. */
define( 'WP_DEBUG',         false );
define( 'WP_DEBUG_LOG',     false );
define( 'WP_DEBUG_DISPLAY', false );
define( 'SCRIPT_DEBUG',     false );
define( 'SAVEQUERIES',      false );

/* WordPress Cache */
define( 'WP_CACHE', true );
define( 'WP_CACHE_KEY_SALT', 'example.com' );

/* Compression */
define( 'COMPRESS_CSS',        true );
define( 'COMPRESS_SCRIPTS',    true );
define( 'CONCATENATE_SCRIPTS', true );
define( 'ENFORCE_GZIP',        true );

/* Updates */
define( 'WP_AUTO_UPDATE_CORE', true );
}" >> /var/www/html/wp-config-sample.php

wp-conf
