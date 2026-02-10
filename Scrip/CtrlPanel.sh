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
    echo -e "${GREEN}    OFFICIAL SCRIPT | WEB INSTALLER (SAFE MODE/NO WIPE)       ${NC}"
    echo -e "${YELLOW}==============================================================${NC}"
    echo -e "${CYAN}        SPECIAL FOR CLOUDFLARE TUNNEL (PORT 8081)             ${NC}"
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
read -p "Buat Password Database (Baru/Lama): " DBPASS
echo ""
echo -e "${YELLOW}Siap! Proses perbaikan/instalasi dimulai...${NC}"
sleep 2

# --- DETEKSI OS ---
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
fi

# Update awal (Aman dijalankan ulang)
apt update -y
apt install -y curl git zip unzip tar lsb-release ca-certificates apt-transport-https software-properties-common gnupg mariadb-server nginx redis-server

# --- PHP SETUP (AUTO DETECT) ---
if [[ "$DISTRO" == "debian" ]]; then
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
elif [[ "$DISTRO" == "ubuntu" ]]; then
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
fi
apt update -y
apt install -y php8.3 php8.3-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip,intl,redis}

# --- INSTALL COMPOSER ---
echo -e "${YELLOW}Cek Composer...${NC}"
if ! command -v composer &> /dev/null; then
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

# --- SETUP DATABASE (SAFE MODE) ---
# Menggunakan IF NOT EXISTS supaya tidak menghapus database lama
echo -e "${YELLOW}Setup Database (Tanpa Hapus Data Lama)...${NC}"
mysql -e "CREATE USER IF NOT EXISTS 'ctrlpaneluser'@'127.0.0.1' IDENTIFIED BY '$DBPASS';"
mysql -e "CREATE DATABASE IF NOT EXISTS ctrlpanel;"
mysql -e "GRANT ALL PRIVILEGES ON ctrlpanel.* TO 'ctrlpaneluser'@'127.0.0.1';"
mysql -e "FLUSH PRIVILEGES;"

# --- SETUP CTRL PANEL FILES ---
mkdir -p /var/www/ctrlpanel
cd /var/www/ctrlpanel

# Cek apakah folder sudah ada isinya?
if [ ! -f "artisan" ]; then
    echo -e "${YELLOW}Folder kosong, mendownload CtrlPanel...${NC}"
    git clone https://github.com/Ctrlpanel-gg/panel.git ./
    echo -e "${YELLOW}Install Vendor (Composer)...${NC}"
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --quiet
    
    echo -e "${YELLOW}Membuat file .env baru...${NC}"
    cp .env.example .env
else
    echo -e "${YELLOW}File CtrlPanel sudah ada, melewati download & install composer...${NC}"
    echo -e "${YELLOW}(Kalau mau update manual, jalankan 'git pull' sendiri)${NC}"
fi

# --- SETUP ENV & KEY (OVERWRITE CONFIG) ---
# Kita update config .env supaya settingan Nginx/Domain bener
echo -e "${YELLOW}Mengupdate Environment (.env)...${NC}"
# Kalau file .env belum ada (kasus aneh), copy dulu
if [ ! -f ".env" ]; then cp .env.example .env; fi

sed -i "s|APP_URL=http://localhost|APP_URL=https://$DOMAIN|" .env
sed -i "s/DB_HOST=127.0.0.1/DB_HOST=127.0.0.1/" .env
sed -i "s/DB_PORT=3306/DB_PORT=3306/" .env
sed -i "s/DB_DATABASE=ctrlpanel/DB_DATABASE=ctrlpanel/" .env
sed -i "s/DB_USERNAME=root/DB_USERNAME=ctrlpaneluser/" .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DBPASS/" .env

# Generate key cuma kalau belum ada key (biar session gak logout)
if ! grep -q "APP_KEY=base64" .env; then
    php artisan key:generate
fi
php artisan storage:link

# --- PERMISSION FIX (SELALU DIJALANKAN BIAR AMAN) ---
echo -e "${YELLOW}Memperbaiki Izin Folder (Permissions)...${NC}"
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data /var/www/ctrlpanel

# --- KONFIGURASI NGINX (PORT 8081) ---
echo -e "${YELLOW}Mengkonfigurasi Nginx (Port 8081)...${NC}"
rm /etc/nginx/sites-enabled/default 2>/dev/null
rm /etc/nginx/sites-enabled/ctrlpanel.conf 2>/dev/null

cat <<EOF > /etc/nginx/sites-available/ctrlpanel.conf
server {
    listen 8081;
    server_name $DOMAIN;
    root /var/www/ctrlpanel/public;
    index index.php;
    
    access_log /var/log/nginx/ctrlpanel.app-access.log;
    error_log  /var/log/nginx/ctrlpanel.app-error.log error;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    # Cloudflare Headers
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
        include /etc/nginx/fastcgi_params;
    }
}
EOF

ln -s /etc/nginx/sites-available/ctrlpanel.conf /etc/nginx/sites-enabled/ctrlpanel.conf
nginx -t
systemctl restart nginx

# --- QUEUE WORKER ---
echo -e "${YELLOW}Restart Service Queue Worker...${NC}"
cat <<EOF > /etc/systemd/system/ctrlpanel.service
[Unit]
Description=Ctrlpanel Queue Worker
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/ctrlpanel/artisan queue:work --sleep=3 --tries=3
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable --now ctrlpanel.service

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}       SAFE MODE SELESAI! LANJUT DI BROWSER       ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "Sekarang buka: https://$DOMAIN"
echo -e "Lalu ikuti langkah ini:"
echo -e "1. Klik Next."
echo -e "2. Masukkan Password Database: $DBPASS"
echo -e "3. Klik Next (Semoga database terhubung lancar)."
echo -e "4. Lanjut isi URL & API Key."
echo -e "5. Buat User Admin di web."
echo ""
echo -e "${CYAN}Note: Script ini tidak menghapus data lamamu.${NC}"
