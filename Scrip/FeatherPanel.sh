#!/bin/bash
# FeatherPanel Installer (HTTPS WRAPPER VERSION)
# Khusus User Cloudflare Tunnel Manual
# Panel: Port 80 | Nginx: Port 443 (HTTPS)

# Cek Root
if [ "$EUID" -ne 0 ]; then
    echo "Tolong jalankan sebagai root (sudo -i)"
    exit 1
fi

# --- WARNA ---
NC='\033[0m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "${CYAN}   FEATHERPANEL HTTPS PROXY INSTALLER     ${NC}"
echo -e "${CYAN}   Mode: Existing Cloudflare Tunnel       ${NC}"
echo -e "${CYAN}==========================================${NC}"
echo ""

# 1. INPUT DOMAIN
echo -e "${YELLOW}Script ini tidak akan meminta Token Cloudflare.${NC}"
read -p "Masukkan Domain Panel (contoh: panel.domain.com): " PANEL_DOMAIN

if [ -z "$PANEL_DOMAIN" ]; then
    echo -e "${RED}Domain tidak boleh kosong!${NC}"
    exit 1
fi

# 2. PILIH VERSI
echo ""
echo "Pilih Versi Panel:"
echo "  [1] Stable (Direkomendasikan)"
echo "  [2] Development (Mungkin tidak stabil)"
read -p "Pilihan (1/2): " VERSI_CHOICE

# 3. BERSIHKAN PORT & INSTALL DEPENDENCIES
echo ""
echo -e "${CYAN}[INFO]${NC} Menyiapkan Environment..."
# Matikan service yang mungkin bentrok sementara
systemctl stop nginx apache2 2>/dev/null

# Install Nginx, OpenSSL, & Docker
apt-get update -qq
apt-get install -qq -y sudo curl nginx openssl

if ! command -v docker &> /dev/null; then
    echo -e "${CYAN}[INFO]${NC} Menginstall Docker..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash >/dev/null 2>&1
    systemctl enable --now docker
fi

# 4. SETUP PANEL (DOCKER)
echo -e "${CYAN}[INFO]${NC} Menyiapkan file panel..."
mkdir -p /var/www/featherpanel
cd /var/www/featherpanel || exit

# URL Download
if [ "$VERSI_CHOICE" == "2" ]; then
    COMPOSE_URL="https://raw.githubusercontent.com/MythicalLTD/FeatherPanel/refs/heads/main/docker-compose.v2.dev.yml"
else
    COMPOSE_URL="https://raw.githubusercontent.com/MythicalLTD/FeatherPanel/refs/heads/main/docker-compose.yml"
fi

# Download & Edit Port ke 80
curl -fsSL -o docker-compose.yml "$COMPOSE_URL"
# Ubah port dari 4831:80 menjadi 80:80 (Biar Nginx gampang akses)
sed -i 's/4831:80/80:80/g' docker-compose.yml

# Modifikasi image jika dev
if [ "$VERSI_CHOICE" == "2" ]; then
    sed -i "s|image: ghcr.io/mythicalltd/featherpanel-backend:latest|image: ghcr.io/mythicalltd/featherpanel-backend:dev-main|g" docker-compose.yml
    sed -i "s|image: ghcr.io/mythicalltd/featherpanel-frontend:latest|image: ghcr.io/mythicalltd/featherpanel-frontend:dev-main|g" docker-compose.yml
fi

# Jalankan Panel
echo -e "${CYAN}[INFO]${NC} Menjalankan Panel..."
docker compose down >/dev/null 2>&1
docker compose up -d
touch /var/www/featherpanel/.installed

# 5. GENERATE SSL (BUATAN SENDIRI)
echo -e "${CYAN}[INFO]${NC} Membuat Sertifikat SSL Lokal..."
mkdir -p /etc/certs/panel
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/certs/panel/privkey.pem \
    -out /etc/certs/panel/fullchain.pem \
    -subj "/C=ID/ST=Server/L=Local/O=FeatherPanel/CN=$PANEL_DOMAIN" >/dev/null 2>&1

# 6. CONFIG NGINX (HTTPS 443 -> DOCKER 80)
echo -e "${CYAN}[INFO]${NC} Membuat Config Nginx (Ala Pterodactyl)..."
cat > /etc/nginx/sites-available/featherpanel.conf <<EOF
server {
    listen 443 ssl;
    server_name $PANEL_DOMAIN;

    # Lokasi Sertifikat SSL
    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;

    client_max_body_size 100m;

    # Proxy ke Docker (Port 80)
    location / {
        proxy_pass http://127.0.0.1:80;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        # Websocket Support (Wajib buat Console)
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

# Aktifkan Nginx
ln -sf /etc/nginx/sites-available/featherpanel.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# 7. SELESAI
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   INSTALASI HTTPS SELESAI!   ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${CYAN}SETTING CLOUDFLARE TUNNEL (WAJIB IKUTI):${NC}"
echo -e "1. Service Type : ${YELLOW}HTTPS${NC}"
echo -e "2. URL          : ${YELLOW}localhost:443${NC}"
echo -e "3. ${RED}PENTING BANGET:${NC} Masuk ke 'Additional application settings' -> 'TLS'"
echo -e "   -> Centang/Aktifkan: ${YELLOW}No TLS Verify${NC}"
echo ""
echo -e "Akses Web: https://$PANEL_DOMAIN"
echo ""
