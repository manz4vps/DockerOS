#!/bin/bash
# ==================================================
# PTERODACTYL PANEL AUTO INSTALLER (UBUNTU 25 FIXED)
# Support: Ubuntu 20.04 - 25.10 & Debian 11 - 13
# ==================================================

if [ "$EUID" -ne 0 ]; then
  echo "Jalankan sebagai ROOT: sudo -i"
  exit 1
fi

# --- FUNGSI UI ---
C_RESET="\e[0m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_RED="\e[1;31m"

banner(){
    clear
    echo -e "${C_BLUE}========================================"
    echo -e "   PTERODACTYL INSTALLER (UBUNTU 25 FIX)"
    echo -e "========================================${C_RESET}"
}

run_step() {
    echo -e "\n${C_BLUE}➜ $1...${C_RESET}"
    eval "$2"
    if [ $? -eq 0 ]; then echo -e "${C_GREEN}✔ Berhasil${C_RESET}"; else echo -e "${C_RED}❌ Gagal${C_RESET}"; exit 1; fi
}

# --- START ---
banner
read -p "🌐 Masukkan Domain (contoh: panel.ku.com): " DOMAIN

# 1. Deteksi OS dengan Codename (Lebih Akurat)
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -sc)

echo -e "${C_YELLOW}Sistem Terdeteksi: $OS ($CODENAME)${C_RESET}"

# 2. Logic Penentuan PHP & Repo
if [[ "$OS" == "ubuntu" ]]; then
    # Cek apakah Ubuntu 24.04 (noble) atau 25.04/25.10 (plucky/questing)
    if [[ "$CODENAME" == "noble" ]] || [[ "$CODENAME" == "plucky" ]] || [[ "$CODENAME" == "questing" ]]; then
        echo -e "${C_GREEN}✅ Ubuntu Modern Terdeteksi ($CODENAME). Menggunakan Repo Bawaan.${C_RESET}"
        
        # Ubuntu 25.10 bawaannya PHP 8.4
        if [[ "$CODENAME" == "questing" ]]; then
            PHP_VERSION="8.4"
        else
            PHP_VERSION="8.3"
        fi
        
        # Hapus repo ondrej biar ga error
        rm -f /etc/apt/sources.list.d/ondrej-php.list
        
        # Jangan pasang repo Redis eksternal (belum support 25.10), pake bawaan aja
        USE_REDIS_REPO=false
    else
        # Ubuntu Lama (20.04 / 22.04)
        echo -e "${C_YELLOW}⚠ Ubuntu Lama Terdeteksi. Menambahkan Repo Ondrej.${C_RESET}"
        PHP_VERSION="8.3"
        add-apt-repository -y ppa:ondrej/php
        USE_REDIS_REPO=true
    fi
elif [[ "$OS" == "debian" ]]; then
    # Logic Debian
    echo -e "${C_GREEN}✅ Debian Terdeteksi.${C_RESET}"
    PHP_VERSION="8.3"
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
    USE_REDIS_REPO=true
fi

# 3. Setup Repo Redis (Hanya kalau didukung)
if [ "$USE_REDIS_REPO" = true ]; then
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
fi

# 4. Update Repo
run_step "Update Repository" "apt-get update -y"

# 5. Install Dependencies & PHP
run_step "Install PHP $PHP_VERSION & Dependencies" "apt-get install -y php$PHP_VERSION php$PHP_VERSION-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server curl tar unzip git"

# 6. Install Composer
run_step "Install Composer" "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"

# 7. Setup Panel
run_step "Download Panel" "mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz && tar -xzvf panel.tar.gz && chmod -R 755 storage/* bootstrap/cache/"

# 8. Setup Database
DB_PASS=$(openssl rand -base64 12)
run_step "Setup Database" "mariadb -u root -e \"CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}'; CREATE DATABASE IF NOT EXISTS panel; GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION; FLUSH PRIVILEGES;\""

# 9. Setup .env
cd /var/www/pterodactyl
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env

# 10. Install Core Dependencies
run_step "Composer Install (Sabar ya, agak lama)" "export COMPOSER_ALLOW_SUPERUSER=1; composer install --no-dev --optimize-autoloader"

# 11. Finalisasi
run_step "Generate Key & Migrate" "php artisan key:generate --force && php artisan migrate --seed --force"

# 12. Permissions & Cron
chown -R www-data:www-data /var/www/pterodactyl/*
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# 13. Setup Nginx (Otomatis deteksi versi PHP sock)
rm /etc/nginx/sites-enabled/default 2>/dev/null
mkdir -p /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj "/C=ID/ST=Dev/L=Indo/O=Dev/CN=${DOMAIN}" -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem 2>/dev/null

cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
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
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf 2>/dev/null
systemctl restart nginx

# 14. Setup Queue
cat > /etc/systemd/system/pteroq.service << EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now redis-server
systemctl enable --now pteroq.service

# 15. Buat Admin
echo -e "\n${C_GREEN}✅ INSTALASI SELESAI!${C_RESET}"
echo -e "Sekarang kita buat akun admin:"
php artisan p:user:make
