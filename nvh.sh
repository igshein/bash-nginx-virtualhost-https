#!/bin/bash

printf 'Enter a domain name: \n'
read domain

mkdir -p /home/$USER/ssl/cert/"$domain"
cd /home/$USER/ssl/cert/"$domain"
sudo openssl genrsa -des3 -out "$domain".key 1024
sudo openssl req -new -key "$domain".key -out "$domain".csr
sudo cp "$domain".key "$domain".key.org
sudo openssl rsa -in "$domain".key.org -out "$domain".key
sudo openssl x509 -req -days 365 -in "$domain".csr -signkey "$domain".key -out "$domain".crt

sudo mkdir -p /var/www/"$domain"/
sudo chown -R debian /var/www/"$domain"/

sudo touch /etc/nginx/sites-available/"$domain"
sudo sh -c "echo '
server {
    listen 80;
    listen 443 ssl;

    server_name $domain;

    root /var/www/$domain;
    index index.php index.html index.htm;

    location / {
        # For MVC
        try_files \$uri \$uri/ /index.php?\$query_string;

        # For Simple
        # try_files \$uri \$uri/ =404;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.3-fpm.sock;
    }

    ssl_certificate /home/$USER/ssl/cert/$domain/$domain.crt;
    ssl_certificate_key /home/$USER/ssl/cert/$domain/$domain.key;
}
' >> /etc/nginx/sites-available/$domain"

sudo ln -s /etc/nginx/sites-available/"$domain" /etc/nginx/sites-enabled/"$domain"
sudo sh -c "echo '127.0.0.1 $domain' >> /etc/hosts"

sudo service nginx restart
