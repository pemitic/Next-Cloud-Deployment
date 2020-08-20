#!/bin/bash

# Copyright 2020, JC Beasley beaswork@gmail.com
#feel free to tweek and adjust to fit your need

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.

# Usage: # installer for nextcloud hub onto Ubuntu 20.04 or Debian 10

####VARIABLES GO HERE####
nc_conf=/etc/apache2/sites-available/nextcloud.conf
#####FUNCTIONS GO HERE####
# ensure running as root
# initiate super user access, enter password when prompted
function SUPERYOU(){
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exec sudo "$0" "$@"
    exit 1
elif [ $(id -u) = "0" ]; then
    echo "Hello superuser"
fi
}

# ensure running as root
SUPERYOU


# install database
apt -y install mariadb-server mariadb-client

# Now you need to enter the database (you will be asked the password you just set):
echo "Please Log in as root"
mysql -u root -p

# secure database
echo "Now Lets Secure the Database Server"
echo ""
mysql_secure_installation 
# log in as root and then select yes on all the options

 # Install PHP and Apache web server and Redis Server
apt-get -y install apache2 php7.2 bzip2 wget unzip 
apt-get -y install libapache2-mod-php php-gd php-json php-mysql php-curl php-mbstring
apt-get -y install php-intl php-imagick php-xml php-zip php-bcmath php-gmp redis-server php-redis

# restart apache2 service
systemctl restart apache2

# Download Nextcloud 19 on Debian 10
wget https://download.nextcloud.com/server/releases/latest-19.zip
unzip latest-19.zip

# move apache2 web folder and set permissions
mv nextcloud /var/www/html/
chown -R www-data:www-data /var/www/html/nextcloud
chmod -R 755 /var/www/html/nextcloud

# create nextcloud configration file 
touch $nc_conf

# add entries to nextcloud configration file
echo "Alias /nextcloud '/var/www/html/nextcloud'" >> $nc_conf
echo "<Directory /var/www/html/nextcloud/>" >> $nc_conf
echo   "Options +FollowSymlinks" >> $nc_conf
echo  "AllowOverride All" >> $nc_conf
echo "<IfModule mod_dav.c>" >> $nc_conf
echo  "Dav off" >> $nc_conf
echo "</IfModule>" >> $nc_conf
echo "SetEnv HOME /var/www/html/nextcloud" >> $nc_conf
echo "SetEnv HTTP_HOME /var/www/html/nextcloud" >> $nc_conf
echo "</Directory>" >> $nc_conf

a2ensite nextcloud
a2enmod rewrite headers env dir mime

# edit php entries
sed -i '/^memory_limit =/s/=.*/= 512M/' /etc/php/7.*/apache2/php.ini
sed -i '/^upload_max_filesize =/s/=.*/= 500M/' /etc/php/7.*/apache2/php.ini
sed -i '/^post_max_size =/s/=.*/= 500M/' /etc/php/7.*/apache2/php.ini
sed -i '/^max_execution_time =/s/=.*/= 300/' /etc/php/7.*/apache2/php.ini
systemctl restart apache2


# information for creating database
CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY 'StrongDBP@SSwo$d'; 
CREATE DATABASE nextcloud; 
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'; 
FLUSH PRIVILEGES;
QUIT

