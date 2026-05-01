#!/bin/bash
# FeatherPanel Installer (PRIVATE & STABLE ONLY)
# By: ManzXD (Owner Mode)
# No Menu Selection - Direct Install Stable Version
# Docker: Port 4831 | Nginx: Port 443 HTTPS

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
BLUE='\033[0;34m'

clear
# --- LOGO FEATHERPANEL ---
echo -e "${BLUE}    ███████╗███████╗ █████╗ ████████╗██╗  ██╗███████╗██████╗ ${NC}"
echo -e "${BLUE}    ██╔════╝██╔════╝██╔══██╗╚══██╔══╝██║  ██║██╔════╝██╔══██╗${NC}"
echo -e "${BLUE}    █████╗  █████╗  ███████║   ██║   ███████║█████╗  ██████╔╝${NC}"
echo -e "${BLUE}    ██╔══╝  ██╔══╝  ██╔══██║   ██║   ██╔══██║██╔══╝  ██╔══██╗${NC}"
echo -e "${BLUE}    ██║     ███████╗██║  ██║   ██║   ██║  ██║███████╗██║  ██║${NC}"
echo -e "${BLUE}    ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${NC}"
echo -e "${CYAN}    ██████╗  █████╗ ███╗   ██╗███████╗██╗     ${NC}"
echo -e "${CYAN}    ██╔══██╗██╔══██╗████╗  ██║██╔════╝██║     ${NC}"
echo -e "${CYAN}    ██████╔╝███████║██╔██╗ ██║█████╗  ██║     ${NC}"
echo -e "${CYAN}    ██╔═══╝ ██╔══██║██║╚██╗██║██╔══╝  ██║     ${NC}"
echo -e "${CYAN}    ██║     ██║  ██║██║ ╚████║███████╗███████╗${NC}"
echo -e "${CYAN}    ╚═╝     ╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝${NC}"
echo -e "${YELLOW}    >>> PRIVATE INSTALLER - STABLE ONLY <<<    ${NC}"
echo ""

# 1. INPUT DOMAIN
read -p "Masukkan Domain Panel (contoh: panel.domain.com): " PANEL_DOMAIN

if [ -z "$PANEL_DOMAIN" ]; then
    echo -e "${RED}Domain tidak boleh kosong!${NC}"
    exit 1
fi

# 2. BERSIHKAN PORT & INSTALL DEPENDENCIES
echo ""
echo -e "${CYAN}[INFO]${NC} Menyiapkan Environment..."
systemctl stop nginx apache2 2>/dev/null

apt-get update -qq
apt-get install -qq -y sudo curl nginx openssl

if ! command -v docker &> /dev/null; then
    echo -e "${CYAN}[INFO]${NC} Menginstall Docker..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash >/dev/null 2>&1
    systemctl enable --now docker
fi

# 3. MENULIS FILE CONFIG (ANTI-DEV UPDATE)
echo -e "${CYAN}[INFO]${NC} Menulis konfigurasi panel pribadi..."
mkdir -p /var/www/featherpanel
cd /var/www/featherpanel || exit

# KITA TULIS LANGSUNG ISINYA DI SINI (Pake Image manz4vps)
cat > docker-compose.yml <<EOF
services:
  mysql:
    image: mariadb:12.1
    container_name: featherpanel_mysql
    restart: unless-stopped
    environment:
      MARIADB_ROOT_PASSWORD: \${MARIADB_ROOT_PASSWORD:-featherpanel_root}
      MARIADB_DATABASE: \${MARIADB_DATABASE:-featherpanel}
      MARIADB_USER: \${MARIADB_USER:-featherpanel}
      MARIADB_PASSWORD: \${MARIADB_PASSWORD:-featherpanel_password}
      MARIADB_AUTO_UPGRADE: "1"
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./mysql/init:/docker-entrypoint-initdb.d
    networks:
      - featherpanel_network
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "root", "-pfeatherpanel_root"]
      timeout: 20s
      retries: 10

  redis:
    image: redis:8.4-alpine
    container_name: featherpanel_redis
    restart: unless-stopped
    command: redis-server --appendonly yes --requirepass \${REDIS_PASSWORD:-featherpanel_redis}
    volumes:
      - redis_data:/data
    networks:
      - featherpanel_network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      timeout: 20s
      retries: 10

  backend:
    # MENGGUNAKAN IMAGE PRIBADI KAMU
    image: manz4vps/panel-backend:private
    container_name: featherpanel_backend
    restart: unless-stopped
    environment:
      - DATABASE_HOST=mysql
      - DATABASE_PORT=3306
      - DATABASE_DATABASE=\${MARIADB_DATABASE:-featherpanel}
      - DATABASE_USER=\${MARIADB_USER:-featherpanel}
      - DATABASE_PASSWORD=\${MARIADB_PASSWORD:-featherpanel_password}
      - DATABASE_ENCRYPTION=xchacha20
      - REDIS_HOST=redis
      - REDIS_PASSWORD=\${REDIS_PASSWORD:-featherpanel_redis}
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "php", "cli", "help"]
      timeout: 20s
      retries: 10
    volumes:
      - featherpanel_attachments:/var/www/html/public/attachments
      - featherpanel_config:/var/www/html/storage/config
      - featherpanel_snapshots:/var/www/html/storage/backups
    networks:
      - featherpanel_network

  frontendv2:
    # MENGGUNAKAN IMAGE PRIBADI KAMU
    image: manz4vps/panel-frontend:private
    container_name: featherpanel_frontendv2
    restart: unless-stopped
    environment:
      - INTERNAL_API_URL=http://backend:80
    volumes: []
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy
      backend:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      timeout: 20s
      retries: 10
    ports:
      # PORT 4831 (PENTING BIAR NGINX JALAN)
      - "4831:80"
    networks:
      - featherpanel_network

volumes:
  mariadb_data:
    driver: local
  redis_data:
    driver: local
  featherpanel_attachments:
    driver: local
  featherpanel_config:
    driver: local
  featherpanel_snapshots:
    driver: local

networks:
  featherpanel_network:
    driver: bridge
EOF

# 4. JALANKAN PANEL
echo -e "${CYAN}[INFO]${NC} Menjalankan Panel (Stable Version)..."
docker compose down >/dev/null 2>&1
docker compose up -d
touch /var/www/featherpanel/.installed

# 5. SETUP SSL & NGINX
echo -e "${CYAN}[INFO]${NC} Menyiapkan Nginx HTTPS..."
mkdir -p /etc/nginx/ssl
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/featherpanel.key \
    -out /etc/nginx/ssl/featherpanel.crt \
    -subj "/C=ID/ST=Server/L=Local/O=FeatherPanel/CN=$PANEL_DOMAIN" >/dev/null 2>&1

cat > /etc/nginx/sites-available/featherpanel.conf <<EOF
server {
    listen 80;
    server_name $PANEL_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl;
    server_name $PANEL_DOMAIN;
    ssl_certificate /etc/nginx/ssl/featherpanel.crt;
    ssl_certificate_key /etc/nginx/ssl/featherpanel.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    client_max_body_size 100m;
    location / {
        # Proxy ke Port 4831
        proxy_pass http://127.0.0.1:4831;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -sf /etc/nginx/sites-available/featherpanel.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# 6. SELESAI
echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}   INSTALASI PRIBADI SELESAI! (STABLE)    ${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${CYAN}SETTING CLOUDFLARE TUNNEL:${NC}"
echo -e "1. Service Type : ${YELLOW}HTTPS${NC}"
echo -e "2. URL          : ${YELLOW}localhost:443${NC}"
echo -e "3. TLS Verify   : ${YELLOW}OFF (No TLS Verify)${NC}"
echo ""
