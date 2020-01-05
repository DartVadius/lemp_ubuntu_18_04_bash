#!/bin/bash

# Function update os
f_update_os () {
    echo "Starting update os ..."
    echo ""
    sleep 1
    apt-get update
    apt-get upgrade -y
    adduser iki
    usermod -aG sudo iki
    echo ""
    sleep 1
}

# Function install LEMP stack
f_install_lemp () {

    echo "deb [arch=amd64] http://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list
    echo "deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" >> /etc/apt/sources.list

    # Download and add Nginx key
    wget http://nginx.org/keys/nginx_signing.key
    apt-key add nginx_signing.key

    # Update new packages from Nginx repo
    echo ""
    echo "Update new packages from Nginx's repository ..."
    echo ""
    sleep 1
    apt update

    # Install and start nginx
    echo ""
    echo "Installing nginx ..."
    echo ""
    sleep 1
    apt install nginx -y
    systemctl enable nginx && systemctl start nginx
    echo ""
    sleep 1

    ########## INSTALL MySQL ##########

    # Add MySQL repository to server Ubuntu 18
    echo "Add MySQL repository to server ..."
    echo ""
    sleep 1
    wget –c https://dev.mysql.com/get/mysql-apt-config_0.8.11-1_all.deb
    dpkg -i mysql-apt-config_0.8.11-1_all.deb

    # Update new packages from MySQL repo
    echo ""
    echo "Update new packages from MySQL's repository ..."
    echo ""
    sleep 1
    apt update

    # Install MySQL server
    echo "Installing MySQL 8 server ..."
    echo ""
    sleep 1
    apt-get install mysql-server
    mysql_secure_installation
    service mysql stop
    mkdir /usr/local/opt/mysql/config
    echo "[mysqld]" >> /usr/local/opt/mysql/config/my.cnf
    echo "default-authentication-plugin=mysql_native_password" >> /usr/local/opt/mysql/config/my.cnf
    service mysql start
    echo ""
    sleep 1

    ########## INSTALL PHP7 ##########
    # This is unofficial repository, it's up to you if you want to use it.
 
    echo "Start install PHP 7 ..."
    echo ""
    sleep 1
    apt-cache pkgnames | grep php7.2
    apt-get install php -y
    apt-get install php-{fpm,bcmath,bz2,gd,mbstring,mysql,zip,cli,common} -y
    apt-get update --fix-missing \
    && apt-get install -y libmcrypt-dev mariadb-client curl git libzip-dev libpng-dev libjpeg-dev libfreetype6-dev \
    && pecl install mcrypt-1.0.2
    echo ""
    sleep 1

    # Config to make PHP-FPM working with Nginx
    echo "Config to make PHP-FPM working with Nginx ..."
    echo ""
    sleep 1
    sed -i 's/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=1/g' /etc/php/7.2/fpm/php.ini
    sed -i 's:user = www-data:user = nginx:g' /etc/php/7.2/fpm/pool.d/www.conf
    sed -i 's:group = www-data:group = nginx:g' /etc/php/7.2/fpm/pool.d/www.conf
    sed -i 's:listen.owner = www-data:listen.owner = nginx:g' /etc/php/7.2/fpm/pool.d/www.conf
    sed -i 's:listen.group = www-data:listen.group = nginx:g' /etc/php/7.2/fpm/pool.d/www.conf
    sed -i 's:;listen.mode = 0660:listen.mode = 0660:g' /etc/php/7.2/fpm/pool.d/www.conf

    # Create web root directory and php info file
    echo "Create web root directory and PHP info file ..."
    echo ""
    sleep 1
    mkdir /etc/nginx/html
    echo "<?php phpinfo(); ?>" > /etc/nginx/html/info.php
    chown -R nginx:nginx /etc/nginx/html

    # Create demo nginx vhost config file
    echo "Create demo Nginx vHost config file ..."
    echo ""
    sleep 1
    mkdir -p /etc/nginx/sites-available
    cat > /etc/nginx/sites-available/default <<"EOF"
server {
    listen 80;
    root /var/www/topmate_app/public;
    index index.php index.html;

    server_name 140.82.59.35;

    location / {
        try_files $uri /index.php?$args;
    }

    location /docs {
        try_files $uri $uri/;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
server {
    listen 8080;
    root /var/www/topmate_api/public;
    index index.php index.html;

    server_name 140.82.59.35;

    location / {
        try_files $uri /index.php?$args;
    }

    location /docs {
        try_files $uri $uri/;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        include fastcgi_params;
        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param PATH_INFO $fastcgi_path_info;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

    # Restart nginx and php-fpm
    echo "Restart Nginx & PHP-FPM ..."
    echo ""
    sleep 1
    systemctl restart nginx
    systemctl restart php7.2-fpm

    # Composer
    curl -sS https://getcomposer.org/installer -o composer-setup.php
    HASH=a5c698ffe4b8e849a443b120cd5ba38043260d5c4023dbf93e1558871f1f07f58274fc6f4c93bcfd858c6bd0775cd8d1
    php -r "if (hash_file('SHA384', 'composer-setup.php') === '$HASH') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer

    # Node + npm
    apt update
    apt install nodejs
    apt install npm

    mkdir -p /var/www/topmate_api
    mkdir -p /var/www/topmate_app

    echo ""
    echo "You can access http://YOUR-SERVER-IP/info.php to see more informations about PHP"
    sleep 1
}

# The sub main function, use to call neccessary functions of installation
f_sub_main () {
    f_update_os
    f_install_lemp
}

# The main function
f_main () {
    f_sub_main
}
f_main

exit
