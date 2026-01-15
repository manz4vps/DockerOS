#!/bin/bash

# panel install
cd /var/www/pterodactyl
php artisan down
curl -L https://github.com/manz4vps/DockerOS/releases/download/v1.0.0/panel.tar.gz | tar -xzv
chmod -R 755 storage/* bootstrap/cache
composer install --no-dev --optimize-autoloader
php artisan view:clear
php artisan config:clear
php artisan migrate --seed --force
chown -R www-data:www-data /var/www/pterodactyl/*
php artisan queue:restart
php artisan up

# done
clear
echo 'made by manz4vps'
