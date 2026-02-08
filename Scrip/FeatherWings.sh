#!/bin/bash
# FeatherWings Fixer & Installer (Auto-Config Edition)
# FIXED VERSION: Forces Config Path & Auto-Opens Nano

# Check for Root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

# Colors
NC=$'\033[0m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
BOLD=$'\033[1m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

echo -e "${GREEN}${BOLD}FeatherWings Installer + Auto Config${NC}"
echo "========================================"

# 1. Update System & Install Dependencies (Tambah nano biar aman)
log_info "Updating package lists..."
apt-get update -qq
apt-get install -y -qq curl sudo ca-certificates gnupg lsb-release nano

# 2. Stop Service if running
log_info "Stopping existing service..."
systemctl stop featherwings 2>/dev/null

# 3. Create Directory Structure (PASTI di /etc/featherpanel)
log_info "Fixing directory structure..."
mkdir -p /etc/featherpanel
mkdir -p /var/lib/featherpanel/volumes
mkdir -p /var/lib/featherpanel/archives
mkdir -p /var/lib/featherpanel/backups
mkdir -p /var/log/featherpanel
mkdir -p /tmp/featherpanel

# 4. Download Wings Binary
ARCH=$(uname -m)
log_info "Downloading fresh Wings binary..."

if [[ "$ARCH" == "x86_64" ]]; then
    curl -L -o /usr/local/bin/featherwings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    curl -L -o /usr/local/bin/featherwings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_arm64"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

chmod +x /usr/local/bin/featherwings
log_success "Binary downloaded."

# 5. Create Systemd Service
log_info "Recreating systemd service..."

cat <<EOF > /etc/systemd/system/featherwings.service
[Unit]
Description=FeatherWings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/featherpanel
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/featherwings --config /etc/featherpanel/config.yml
Restart=always
RestartSec=5
StartLimitInterval=180
StartLimitBurst=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# 6. Enable Service
systemctl daemon-reload
systemctl enable featherwings
log_success "System installed successfully!"

# 7. AUTO CONFIGURATION SECTION
echo ""
echo -e "${YELLOW}=========================================================${NC}"
echo -e "${YELLOW}               WAKTUNYA KONFIGURASI!                     ${NC}"
echo -e "${YELLOW}=========================================================${NC}"
echo "Siapkan token konfigurasi dari Admin Panel sekarang."
echo "Tips untuk Cloudflare Tunnel:"
echo "1. Paste config-nya."
echo "2. Ubah 'ssl: true' menjadi 'false'."
echo "3. Ubah 'port: 443' (atau lain) menjadi '8080'."
echo ""
read -p "Tekan [ENTER] untuk membuka editor Nano..."

# Buka Nano langsung ke file config
nano /etc/featherpanel/config.yml

# Setelah user keluar dari nano (CTRL+X, Y, Enter), lanjut ke sini:
echo ""
log_info "Menyalakan FeatherWings..."
systemctl restart featherwings
sleep 2

# Cek status tanpa bikin stuck layar
log_info "Status Terakhir:"
systemctl status featherwings --no-pager

echo ""
echo -e "${GREEN}${BOLD}SELESAI! Cek Panel kamu sekarang.${NC}"
