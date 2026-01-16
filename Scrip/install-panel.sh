#!/bin/bash
# ==================================================
# PTERODACTYL PANEL AUTO INSTALLER (CUSTOM EDITION)
# Base Script: Punya Kamu
# Fixed by: ManzXD (Ubuntu 22/24 Support)
# ==================================================

# ---------------- CEK ROOT DULU ----------------
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31mSTOP! Kamu harus menjalankan script ini sebagai ROOT.\e[0m"
  echo -e "Silakan ketik perintah ini dulu: \e[1;33msudo -i\e[0m"
  exit 1
fi

# ---------------- CONFIG ----------------
PHP_VERSION="8.3"
DOMAIN=""

# ---------------- UI THEME ----------------
clear
echo -e "\e[1;36m"
cat << "EOF"
██████╗ ███████╗████████╗███████╗██████╗  ██████╗ 
██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗
██████╔╝█████╗     ██║   █████╗  ██████╔╝██║   ██║
██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗██║   ██║
██║     ███████╗   ██║   ███████╗██║  ██║╚██████╔╝
╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ 
        PTERODACTYL INSTALLER (MANZ-FIX)
EOF
echo -e "\e[0m"
read -p "🌐 Enter domain (panel.example.com): " DOMAIN

# --- Dependencies ---
echo -e "\e[1;34m➜ Update & Install Dependencies...\e[0m"

# FIX ERROR LOCK (PENTING)
rm -f /var/lib/apt/lists/lock
rm -f /var/cache/apt/archives/lock
rm -f /var/lib/dpkg/lock*

apt-get update -y
apt-get install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -sc)

# --- REPO FIX LOGIC (BAGIAN PENTING) ---
echo -e "\e[1;34m➜ Configuring Repositories...\e[0m"

if [[ "$OS" == "ubuntu" ]]; then
    # Bersihkan repo lama
    rm -f /etc/apt/sources.list.d/ondrej-php.list
    rm -f /etc/apt/sources.list.d/sury-php.list
    
    if [[ "$CODENAME" == "noble" ]]; then
        # Ubuntu 24.04 (Noble)
        echo -e "\e[1;32m✅ Ubuntu 24.04 Detected. Menggunakan PHP Native (No Repo).\e[0m"
    else
        # Ubuntu 22.04 (Jammy)
        echo -e "\e[1;33m🔥 Ubuntu 22.04 Detected. Menambahkan PPA Ondrej...\e[0m"
        LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    fi
elif [[ "$OS" == "debian" ]]; then
    echo -e "\e[1;33m🔥 Debian Detected. Adding SURY Repo...\e[0m"
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt-get update -y

# --- Install PHP + extensions ---
echo -e "\e[1;34m➜ Installing PHP ${PHP_VERSION}...\e[0m"
apt-get install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server

if [ $? -ne 0 ]; then
    echo -e "\e[1;31m❌ GAGAL INSTALL PHP! Script berhenti.\e[0m"
    exit 1
fi

# --- Install Composer ---
echo -e "\e[1;34m➜ Installing Composer...\e[0m"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# --- Download Pterodactyl Panel ---
echo -e "\e[1;34m➜ Downloading Panel...\e[0m"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# --- MariaDB Setup ---
echo -e "\e[1;34m➜ Configuring Database...\e[0m"
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=$(openssl rand -base64 12) # Password Random biar aman

mariadb -u root -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -u root -e "CREATE DATABASE ${DB_NAME};"
mariadb -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -u root -e "FLUSH PRIVILEGES;"

# --- .env Setup ---
if [ ! -f ".env.example" ]; then
    curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
fi
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi

# --- Install PHP dependencies ---
echo -e "\e[1;34m➜ Installing Dependencies (Composer)...\e[0m"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# --- Generate Application Key ---
echo -e "\e[1;34m➜ Generating Key & Migrating...\e[0m"
php artisan key:generate --force
php artisan migrate --seed --force

# --- Permissions ---
chown -R www-data:www-data /var/www/pterodactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# --- Nginx Setup ---
echo -e "\e[1;34m➜ Configuring Nginx...\e[0m"
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=ID/ST=ManzXD/L=Indo/O=Manz/CN=${DOMAIN}" \
-keyout privkey.pem -out fullchain.pem

rm /etc/nginx/sites-enabled/default 2>/dev/null

tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf || true
nginx -t && systemctl restart nginx

# --- Queue Worker ---
tee /etc/systemd/system/pteroq.service > /dev/null << EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
clear

# --- Admin User ---
echo -e "\e[1;36m➜ Creating Admin User...\e[0m"
cd /var/www/pterodactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
php artisan p:user:make

# --- Animated Info ---
echo -e "\n\e[1;32m✔ Pterodactyl Panel Setup Complete!\e[0m"
echo -ne "\e[1;34mFinalizing installation"
for i in {1..5}; do
    echo -n "."
    sleep 0.5
done
echo -e "\n"

echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;36m  ✅ Installation Completed Successfully! \e[0m"
echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;32m  🌐 Your Panel URL: \e[1;37mhttps://${DOMAIN}\e[0m"
echo -e "\e[1;32m  📂 Panel Directory: \e[1;37m/var/www/pterodactyl\e[0m"
echo -e "\e[1;32m  🔑 DB User: \e[1;37m${DB_USER}\e[0m"
echo -e "\e[1;32m  🔑 DB Password: \e[1;37m${DB_PASS}\e[0m"
echo -e "\e[1;33m━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\e[0m"
echo -e "\e[1;35m  🎉 Enjoy your Pterodactyl Panel! \e[0m"
