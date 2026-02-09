#!/bin/bash

# --- KONFIGURASI WARNA & STYLE ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- FUNGSI LOGO TEBEL & KEREN ---
show_logo() {
    clear
    # Bagian Logo ASCII (Cyan Bold)
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
██████╗ ████████╗██████╗ ██╗     ██████╗  █████╗ ███╗   ██╗███████╗██╗     
██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     
██║        ██║   ██████╔╝██║     ██████╔╝███████║██╔██╗ ██║█████╗  ██║     
██║        ██║   ██╔══██╗██║     ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║     
╚██████╗   ██║   ██║  ██║███████╗██║     ██║  ██║██║ ╚████║███████╗███████╗
 ╚═════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝
EOF
    echo -e "${NC}"
    
    # Bagian Footer Credit (Kustom manz4vps)
    echo -e "${YELLOW}==============================================================${NC}"
    echo -e "${GREEN}    >> OFFICIAL SCRIPT | DEVELOPED BY: ${PURPLE}${BOLD}MANZ4VPS${NC}${GREEN} <<    ${NC}"
    echo -e "${YELLOW}==============================================================${NC}"
    echo -e "${CYAN}       OS Auto-Detect: Debian 10-12 & Ubuntu 20.04-22.04      ${NC}"
    echo ""
}

# Cek apakah dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}${BOLD}[ERROR] Gagal! Script ini wajib dijalankan sebagai root.${NC}" 
   exit 1
fi

# Tampilkan Logo
show_logo

# --- INPUT USER ---
echo -e "${BOLD}Silakan isi data berikut:${NC}"
read -p "Masukkan Domain Dashboard (contoh: billing.domain.com): " DOMAIN
read -p "Masukkan Email untuk SSL (contoh: emailmu@gmail.com): " EMAIL
read -p "Buat Password Database Baru (untuk user ctrlpanel): " DBPASS
echo ""
echo -e "${YELLOW}Siap! Proses instalasi otomatis dimulai dalam 3 detik...${NC}"
sleep 3

# --- DETEKSI OS ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    DISTRO=$ID
    VERSION=$VERSION_ID
else
    echo -e "${RED}OS tidak dapat dideteksi. Script berhenti.${NC}"
    exit 1
fi

echo -e "${GREEN}OS Terdeteksi: $OS ($DISTRO $VERSION)${NC}"

# Update awal
apt update -y
apt install -y curl git zip unzip tar lsb-release ca-certificates apt-transport-https software-properties-common gnupg

# --- BRANCHING INSTALLATION BERDASARKAN OS ---
if [[ "$DISTRO" == "debian" ]]; then
    echo -e "${YELLOW}Mengkonfigurasi Repositori untuk Debian...${NC}"
    
    # PHP Repo Debian
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
    
    # Redis Repo
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

elif [[ "$DISTRO" == "ubuntu" ]]; then
    echo -e "${YELLOW}Mengkonfigurasi Repositori untuk Ubuntu...${NC}"
    
    # PHP Repo Ubuntu
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
    
    # Redis Repo
    curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
    
    # MariaDB Repo Setup
    curl -LsS https://r.mariadb.com/downloads/mariadb_repo_setup | bash

else
    echo -e "${RED}Distro $DISTRO tidak didukung secara otomatis oleh script ini.${NC}"
    exit 1
fi

# Update setelah tambah repo
apt update -y

# --- INSTALL DEPENDENCIES ---
echo -e "${YELLOW}Menginstall paket-paket yang diperlukan (PHP 8.3, Nginx, MariaDB, Redis)...${NC}"
apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis} mariadb-server nginx git redis-server certbot python3-certbot-nginx

# Enable Redis
systemctl enable --now redis-server

# --- INSTALL COMPOSER ---
echo -e "${YELLOW}Menginstall Composer...${NC}"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# --- SETUP CTRL PANEL FILES ---
echo -e "${YELLOW}Mendownload Source Code CtrlPanel...${NC}"
mkdir -p /var/www/ctrlpanel
cd /var/www/ctrlpanel
# Hapus folder jika sudah ada isinya biar clean install
rm -rf *
git clone https://github.com/Ctrlpanel-gg/panel.git ./

# --- SETUP DATABASE ---
echo -e "${YELLOW}Membuat Database dan User MySQL...${NC}"
mysql -e "CREATE USER IF NOT EXISTS 'ctrlpaneluser'@'127.0.0.1' IDENTIFIED BY '$DBPASS';"
mysql -e "CREATE DATABASE IF NOT EXISTS ctrlpanel;"
mysql -e "GRANT ALL PRIVILEGES ON ctrlpanel.* TO 'ctrlpaneluser'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"

# --- INSTALL DEPENDENCIES PANEL ---
echo -e "${YELLOW}Menjalankan Composer Install (Mohon Tunggu)...${NC}"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

# --- SETUP ENV & KEY ---
echo -e "${YELLOW}Mengatur Environment (.env)...${NC}"
cp .env.example .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DBPASS/" .env
sed -i "s|APP_URL=http://localhost|APP_URL=https://$DOMAIN|" .env
# Set database info explicitly just in case
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=3306/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=ctrlpanel/DB_DATABASE=ctrlpanel/" .env
sed -i "s/DB_USERNAME=root/DB_USERNAME=ctrlpaneluser/" .env

php artisan key:generate
php artisan storage:link

# --- KONFIGURASI NGINX ---
echo -e "${YELLOW}Mengkonfigurasi Nginx...${NC}"
rm /etc/nginx/sites-enabled/default

# Config sementara untuk port 80 (biar Certbot jalan)
cat <<EOF > /etc/nginx/sites-available/ctrlpanel.conf
server {
    listen 80;
    server_name $DOMAIN;
    root /var/www/ctrlpanel/public;
    index index.php;
    
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }
}
EOF

ln -s /etc/nginx/sites-available/ctrlpanel.conf /etc/nginx/sites-enabled/ctrlpanel.conf
systemctl restart nginx

# --- SETUP SSL (CERTBOT) ---
echo -e "${YELLOW}Meminta sertifikat SSL dari Let's Encrypt...${NC}"
# Kita stop nginx sebentar jika certbot butuh port 80, tapi pakai plugin nginx lebih aman
certbot certonly --nginx -d $DOMAIN --non-interactive --agree-tos -m $EMAIL

# --- KONFIGURASI NGINX FULL (DENGAN SSL) ---
cat <<EOF > /etc/nginx/sites-available/ctrlpanel.conf
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    root /var/www/ctrlpanel/public;
    index index.php;

    access_log /var/log/nginx/ctrlpanel.app-access.log;
    error_log  /var/log/nginx/ctrlpanel.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        include /etc/nginx/fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Restart Nginx dengan config baru
nginx -t
systemctl restart nginx

# --- PERMISSIONS & CRON ---
echo -e "${YELLOW}Mengatur Permission dan Cronjob...${NC}"
chown -R www-data:www-data /var/www/ctrlpanel/
chmod -R 755 /var/www/ctrlpanel/storage /var/www/ctrlpanel/bootstrap/cache

# Menambahkan cronjob
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/ctrlpanel/artisan schedule:run >> /dev/null 2>&1") | crontab -

# --- QUEUE WORKER ---
echo -e "${YELLOW}Membuat Service Queue Worker...${NC}"
cat <<EOF > /etc/systemd/system/ctrlpanel.service
[Unit]
Description=Ctrlpanel Queue Worker

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/ctrlpanel/artisan queue:work --sleep=3 --tries=3
StartLimitBurst=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now ctrlpanel.service

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}           INSTALASI SELESAI!                     ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "Akses Dashboard di: https://$DOMAIN"
echo -e "Silakan buka link tersebut untuk menyelesaikan Setup Admin."
echo -e "Database Info (Jika diminta):"
echo -e "  - DB Host: 127.0.0.1"
echo -e "  - DB Name: ctrlpanel"
echo -e "  - DB User: ctrlpaneluser"
echo -e "  - DB Pass: $DBPASS"
echo ""
echo -e "${CYAN}Terima kasih telah menggunakan script MANZ4VPS!${NC}"
