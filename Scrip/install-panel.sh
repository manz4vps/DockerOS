#!/bin/bash
# ==================================================
# PTERODACTYL PANEL AUTO INSTALLER (UNIVERSAL FIX)
# Support: Ubuntu 22.04 (Jammy) & 24.04 (Noble)
# ==================================================

# ---------------- CEK ROOT DULU ----------------
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31mSTOP! Kamu harus menjalankan script ini sebagai ROOT.\e[0m"
  echo -e "Silakan ketik perintah ini dulu: \e[1;33msudo -i\e[0m"
  exit 1
fi

# ---------------- UI THEME ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

# DEFINISI PHP VERSION
PHP_VERSION="8.3"

line(){ echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }
step(){ echo -e "${C_BLUE}➜ $1${C_RESET}"; }
ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }

banner(){
clear
echo -e "${C_CYAN}"
cat << "EOF"
██████╗ ███████╗████████╗███████╗██████╗  ██████╗ 
██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗██╔═══██╗
██████╔╝█████╗     ██║   █████╗  ██████╔╝██║   ██║
██╔═══╝ ██╔══╝     ██║   ██╔══╝  ██╔══██╗██║   ██║
██║     ███████╗   ██║   ███████╗██║  ██║╚██████╔╝
╚═╝     ╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝ ╚═════╝ 
        PTERODACTYL PANEL INSTALLER
EOF
echo -e "${C_RESET}"
line
echo -e "${C_GREEN}⚡ Auto-Detect: Ubuntu Jammy / Noble${C_RESET}"
echo -e "${C_PURPLE}🧠 Fixed by ManzXD Helper${C_RESET}"
line
}

# ---------------- START ----------------
banner
read -p "🌐 Enter domain (panel.example.com): " DOMAIN

# --- Dependencies ---
clear
step "Update & Install Dependencies..."
# Kita matikan error sementara biar apt update tetep jalan meski ada error dikit
apt-get update || true
apt-get install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -sc)

step "Configuring PHP Repositories..."

# --- LOGIKA BARU (SUPPORT UBUNTU 24 & 22) ---
if [[ "$OS" == "ubuntu" ]]; then
    if [[ "$CODENAME" == "noble" ]]; then
        # === KHUSUS UBUNTU 24 (NOBLE) ===
        echo -e "${C_GREEN}✅ Ubuntu 24.04 (Noble) Terdeteksi.${C_RESET}"
        echo -e "${C_YELLOW}⚡ Menggunakan PHP bawaan sistem (Tanpa Repo Tambahan).${C_RESET}"
        # Hapus repo ondrej kalo gak sengaja ada, biar gak bikin konflik
        rm -f /etc/apt/sources.list.d/ondrej-php.list
        rm -f /etc/apt/sources.list.d/sury-php.list
        
    else
        # === KHUSUS UBUNTU 22 (JAMMY) ===
        echo -e "${C_YELLOW}🔥 Ubuntu $CODENAME Terdeteksi. Menggunakan Fix Manual SSL...${C_RESET}"
        
        # 1. Hapus list lama biar bersih
        rm -f /etc/apt/sources.list.d/ondrej-php.list
        rm -f /etc/apt/sources.list.d/sury-php.list

        # 2. Matikan Cek SSL (Solusi Error Certificate 2026)
        echo 'Acquire::https::ppa.launchpadcontent.net::Verify-Peer "false";' > /etc/apt/apt.conf.d/99-trust-launchpad

        # 3. Masukin Repo Launchpad secara Manual
        echo "deb [trusted=yes] https://ppa.launchpadcontent.net/ondrej/php/ubuntu $CODENAME main" > /etc/apt/sources.list.d/ondrej-php.list
    fi
    
elif [[ "$OS" == "debian" ]]; then
    # Kalo debian pake cara standar sury
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

# Add Redis GPG key and repo
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

step "Updating Package Lists..."
apt-get update

# --- Install PHP + extensions ---
clear
step "Installing PHP $PHP_VERSION..."
apt-get install -y php$PHP_VERSION php$PHP_VERSION-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server

# --- Install Composer ---
clear
step "Installing Composer..."
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# --- Download Pterodactyl Panel ---
clear
step "Downloading Panel..."
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# --- MariaDB Setup ---
step "Configuring Database..."
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=$(openssl rand -base64 12) 

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
clear
step "Installing PHP dependencies (Composer)..."
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# --- Generate Application Key ---
php artisan key:generate --force

# --- Run Migrations ---
step "Migrating Database..."
php artisan migrate --seed --force

# --- Permissions ---
chown -R www-data:www-data /var/www/pterodactyl/*
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# --- Nginx Setup ---
clear
step "Configuring Nginx..."
mkdir -p /etc/certs/panel
cd /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
-subj "/C=ID/ST=DockerOS/L=Manz/O=DockerOS/CN=${DOMAIN}" \
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
ok "Nginx online"

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
ok "Queue running"

# --- Admin User ---
clear
step "Create admin user"
cd /var/www/pterodactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
php artisan p:user:make

# ---------------- DONE ----------------
line
echo -e "${C_GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY${C_RESET}"
line
echo -e "${C_CYAN}🌐 Panel URL    : ${C_WHITE}https://${DOMAIN}${C_RESET}"
echo -e "${C_CYAN}🗄 DB User      : ${C_WHITE}${DB_USER}${C_RESET}"
echo -e "${C_CYAN}🔑 DB Password  : ${C_WHITE}${DB_PASS}${C_RESET}"
line
