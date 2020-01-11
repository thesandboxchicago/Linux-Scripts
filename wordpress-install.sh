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
  if [ -e /etc/centos-release ]; then
    DISTRO="CentOS"
  elif [ -e /etc/debian_version ]; then
    DISTRO=$( lsb_release -is )
  elif [ -e /etc/fedora-release ]; then
    DISTRO="Fedora"
  elif [ -e /etc/redhat-release ]; then
    DISTRO="Redhat"
  else
    echo "Your distribution is not supported (yet)."
    exit
  fi
}

## Check distro
dist-check

## Start Installation Of Packages
function install-essentials() {
  if [ "$DISTRO" == "Ubuntu" ]; then
    apt-get install apache2 mysql-server php7.2 php-curl php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
    dpkg -i mod-pagespeed-*.deb
    apt-get -f install
  elif [ "$DISTRO" == "Debian" ]; then
    apt-get install apache2 php7.3 php-curl libapache2-mod-php php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick php-soap php-fpm php-zip php-json -y
    wget http://repo.mysql.com/mysql-apt-config_0.8.13-1_all.deb
    dpkg -i mysql-apt-config_0.8.13-1_all.deb
    rm mysql-apt-config_0.8.13-1_all.deb 
    apt-get update
    apt-get install mysql-server -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
    dpkg -i mod-pagespeed-*.deb
    apt-get -f install
  elif [ "$DISTRO" == "Raspbian" ]; then
    apt-get install apache2 mysql-server php7.0 php-curl php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_amd64.deb
    dpkg -i mod-pagespeed-*.deb
    apt-get -f install
  elif [ "$DISTRO" == "CentOS" ]; then
    yum install epel-release -y
    yum install apache2 mysql-server php7.0 php-curl php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm
    sudo yum install at 
    sudo rpm -U mod-pagespeed-*.rpm
  elif [ "$DISTRO" == "Fedora" ]; then
    dnf install apache2 mysql-server php7.0 php-curl php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm
    sudo yum install at 
    sudo rpm -U mod-pagespeed-*.rpm
  elif [ "$DISTRO" == "Redhat" ]; then
    dnf install apache2 mysql-server php7.0 php-curl php-gd php-mbstring php-xml php-xmlrpc php-mysql php-bcmath php-imagick -y
    wget https://dl-ssl.google.com/dl/linux/direct/mod-pagespeed-stable_current_x86_64.rpm
    sudo yum install at 
    sudo rpm -U mod-pagespeed-*.rpm
  fi
    wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
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

## Enable Mod Rewrite
function mod-rewrite() {
sudo a2enmod rewrite
echo "<Directory /var/www>
    Options Indexes FollowSymLinks MultiViews
    AllowOverride All
    Require all granted
</Directory>" >> /etc/apache2/sites-available/000-default.conf
}

## Run Mode Rewite
mod-rewrite

## Enable htacess
function enable-htacess() {
echo \
"# Enable Rewrite
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# Disable Indexing
Options -Indexes
# Change Upload Limit
php_value upload_max_filesize 64M
php_value post_max_size 64M
php_value max_execution_time 300
php_value max_input_time 300" \
 >> /var/www/.htaccess
}

## Run Htacess
enable-htacess

## Function for correct permission
function correct-permissions() {
cd /var/www/
chown www-data:www-data  -R *
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
}

## Run correct permissions 
correct-permissions

## Restart Apache2
function apache-restart() {
if pgrep systemd-journal; then
  systemctl enable apache2
  systemctl restart apache2
else
   service apache2 restart
fi
}

## Run Apache2 Restart
apache-restart

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
