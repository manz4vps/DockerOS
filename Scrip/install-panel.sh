#!/bin/bash
# ==================================================
# PTERODACTYL PANEL INSTALLER (STICKY HEADER + PHP 8.4)
# Support: Ubuntu 25.10 (Force 8.4), 24.04, 22.04
# ==================================================

# ---------------- CEK ROOT ----------------
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31mSTOP! Jalankan sebagai ROOT: sudo -i\e[0m"
  exit 1
fi

# ---------------- WARNA ----------------
C_RESET="\e[0m"
C_RED="\e[1;31m"
C_GREEN="\e[1;32m"
C_YELLOW="\e[1;33m"
C_BLUE="\e[1;34m"
C_PURPLE="\e[1;35m"
C_CYAN="\e[1;36m"
C_WHITE="\e[1;37m"
C_GRAY="\e[1;90m"

# ---------------- FUNGSI UTAMA ----------------

cleanup_terminal() {
    tput csr 0 $(tput lines)
    tput cnorm
}
trap cleanup_terminal EXIT

line(){ echo -e "${C_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"; }

banner(){
    echo -e "${C_CYAN}"
    echo "   PTERODACTYL PANEL INSTALLER (PHP 8.4 EDITION)"
    echo -e "${C_RESET}"
    echo -e "${C_PURPLE}   Powered by ManzXD Helper${C_RESET}"
    line
}

# --- FUNGSI STICKY HEADER ---
run_step() {
    local message="$1"
    local command="$2"
    local TOTAL_LINES=$(tput lines)
    local HEADER_SIZE=10 

    clear
    banner
    echo -e "${C_BLUE}➜ PROSES SAAT INI:${C_RESET}"
    echo -e "${C_YELLOW}   $message${C_RESET}"
    line
    tput csr $HEADER_SIZE $TOTAL_LINES
    tput cup $HEADER_SIZE 0
    eval "$command"
    tput csr 0 $TOTAL_LINES
}

ok(){ echo -e "${C_GREEN}✔ $1${C_RESET}"; }

# ---------------- START ----------------
tput csr 0 $(tput lines)
clear

banner
read -p " 🌐 Masukkan Domain (panel.domain.com): " DOMAIN

# --- Dependencies ---
run_step "Update & Install Dependencies" "apt-get update -y && apt-get install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release software-properties-common"

# --- DETECT OS & PHP VERSION ---
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
CODENAME=$(lsb_release -sc)
RELEASE=$(lsb_release -rs)

# LOGIKA PHP 8.4 (Ubuntu 25.10)
if [[ "$OS" == "ubuntu" ]]; then
    if [[ "$RELEASE" == "25.10" ]] || [[ "$RELEASE" == "25.04" ]]; then
        # === UBUNTU 25.10 -> PHP 8.4 ===
        # Kita pakai PHP bawaan 8.4, tapi kita tambahin flag composer
        # supaya Pterodactyl gak protes minta 8.3
        PHP_VERSION="8.4"
        COMPOSER_FLAGS="--no-dev --optimize-autoloader --ignore-platform-reqs"
        
        # Hapus repo ondrej biar ga error unsigned
        rm -f /etc/apt/sources.list.d/ondrej-php.list
        
    elif [[ "$RELEASE" == "24.04" ]] || [[ "$RELEASE" == "24.10" ]]; then
        # Ubuntu 24 -> PHP 8.3 (Bawaan/Ondrej Noble)
        PHP_VERSION="8.3"
        COMPOSER_FLAGS="--no-dev --optimize-autoloader"
        # Jaga-jaga repo manual
        echo "deb [trusted=yes] https://ppa.launchpadcontent.net/ondrej/php/ubuntu noble main" > /etc/apt/sources.list.d/ondrej-php.list
        apt-get update > /dev/null 2>&1
    else
        # Ubuntu Lama -> PHP 8.3 (Ondrej PPA)
        PHP_VERSION="8.3"
        COMPOSER_FLAGS="--no-dev --optimize-autoloader"
        add-apt-repository -y ppa:ondrej/php > /dev/null 2>&1
    fi
else
    # Debian -> PHP 8.3 (Sury)
    PHP_VERSION="8.3"
    COMPOSER_FLAGS="--no-dev --optimize-autoloader"
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list > /dev/null
    apt-get update > /dev/null 2>&1
fi

# Redis Repo
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list > /dev/null
apt-get update > /dev/null 2>&1

# --- Install PHP + extensions ---
run_step "Menginstall PHP $PHP_VERSION & Extension" "apt-get install -y php$PHP_VERSION php$PHP_VERSION-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server"

# --- Install Composer ---
run_step "Menginstall Composer" "curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer"

# --- Download Pterodactyl Panel ---
run_step "Mendownload & Ekstrak Panel" "mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl && curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz && tar -xzvf panel.tar.gz && chmod -R 755 storage/* bootstrap/cache/"

# --- MariaDB Setup ---
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS=$(openssl rand -base64 12) 

run_step "Setup Database MariaDB" "mariadb -u root -e \"CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';\" && mariadb -u root -e \"CREATE DATABASE IF NOT EXISTS ${DB_NAME};\" && mariadb -u root -e \"GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;\" && mariadb -u root -e \"FLUSH PRIVILEGES;\""

# --- .env Setup ---
cd /var/www/pterodactyl
if [ ! -f ".env" ]; then cp .env.example .env; fi
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env

# --- Install PHP dependencies ---
# INI KUNCINYA: Flag COMPOSER_FLAGS berisi --ignore-platform-reqs untuk Ubuntu 25
run_step "Install Dependency PHP (Composer)" "cd /var/www/pterodactyl && export COMPOSER_ALLOW_SUPERUSER=1 && composer install $COMPOSER_FLAGS"

# --- Generate Key ---
run_step "Generate App Key" "cd /var/www/pterodactyl && php artisan key:generate --force"

# --- Run Migrations ---
run_step "Migrating Database (Membuat Tabel)" "cd /var/www/pterodactyl && php artisan migrate --seed --force"

# --- Permissions ---
run_step "Setup Permission & Cronjob" "chown -R www-data:www-data /var/www/pterodactyl/* && apt install -y cron && systemctl enable --now cron && (crontab -l 2>/dev/null; echo '* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1') | sort -u | crontab -"

# --- Nginx Setup ---
run_step "Setup Nginx & SSL" "
mkdir -p /etc/certs/panel && \
cd /etc/certs/panel && \
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -subj '/C=ID/ST=DockerOS/L=Manz/O=DockerOS/CN=${DOMAIN}' -keyout privkey.pem -out fullchain.pem && \
rm /etc/nginx/sites-enabled/default 2>/dev/null; \
cat > /etc/nginx/sites-available/pterodactyl.conf << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\\\$server_name\\\$request_uri;
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
        try_files \\\$uri \\\$uri/ /index.php?\\\$query_string;
    }
    location ~ \.php\\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE \"upload_max_filesize=100M \n post_max_size=100M\";
        fastcgi_param SCRIPT_FILENAME \\\$document_root\\\$fastcgi_script_name;
    }
    location ~ /\.ht { deny all; }
}
EOF
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf || true && \
nginx -t && systemctl restart nginx
"

# --- Queue Worker ---
run_step "Mengaktifkan Queue Worker" "
cat > /etc/systemd/system/pteroq.service << EOF
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
systemctl daemon-reload && \
systemctl enable --now redis-server && \
systemctl enable --now pteroq.service
"

# --- Admin User ---
# Kembalikan terminal ke normal full screen untuk input user
tput csr 0 $(tput lines)
clear
banner
echo -e "${C_BLUE}➜ Membuat User Admin${C_RESET}"
echo -e "${C_GRAY}(Silakan isi data user di bawah ini)${C_RESET}"
echo ""
cd /var/www/pterodactyl
php artisan p:user:make

# ---------------- DONE ----------------
clear
banner
echo -e "${C_GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY${C_RESET}"
line
echo -e "${C_CYAN}🌐 Panel URL    : ${C_WHITE}https://${DOMAIN}${C_RESET}"
echo -e "${C_CYAN}🗄 DB User      : ${C_WHITE}${DB_USER}${C_RESET}"
echo -e "${C_CYAN}🔑 DB Password  : ${C_WHITE}${DB_PASS}${C_RESET}"
line
