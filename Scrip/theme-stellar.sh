#!/bin/bash

# =======================================================
#  INSTALLER KHUSUS THEME STELLAR (UPDATE LINK)
#  File: panel.tar.gz
# =======================================================

# Definisi Warna
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

# Cek Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan sebagai root (sudo).${RESET}" 
   exit 1
fi

# Cek Direktori
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Direktori /var/www/pterodactyl tidak ditemukan.${RESET}"
    exit 1
fi

clear
echo -e "${BLUE}=========================================${RESET}"
echo -e "${YELLOW}    INSTALL THEME STELLAR (BY MANZ)      ${RESET}"
echo -e "${BLUE}=========================================${RESET}"
echo ""

# -------------------------------------------------------
# 1. SETUP DEPENDENCIES
# -------------------------------------------------------
echo -e "${YELLOW}[1/4] Memeriksa Dependencies...${RESET}"

# Setup Keyrings
if [ ! -d "/etc/apt/keyrings" ]; then
  mkdir -p /etc/apt/keyrings
fi

# Install Node.js 16.x (Wajib buat Ptero v1.11.x / Stellar)
if ! command -v node &> /dev/null; then
    echo "Menginstall Node.js..."
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt update
    sudo apt install -y nodejs
fi

# Install Yarn
if ! command -v yarn &> /dev/null; then
    echo "Menginstall Yarn..."
    npm i -g yarn
fi

# Install Tar & Curl
sudo apt install -y tar curl

# -------------------------------------------------------
# 2. DOWNLOAD & EXTRACT (Update Bagian Ini)
# -------------------------------------------------------
echo -e "${YELLOW}[2/4] Mendownload & Ekstrak Theme...${RESET}"

# LINK BARU DARI KAMU
DOWNLOAD_URL="https://github.com/manz4vps/DockerOS/releases/download/v1.0.1/panel.tar.gz"
FILE_PATH="/var/www/panel.tar.gz"

# Download File
echo "Downloading..."
curl -L -o "$FILE_PATH" "$DOWNLOAD_URL"

if [ -f "$FILE_PATH" ]; then
    echo "Mengekstrak file ke folder Pterodactyl..."
    
    # Ekstrak tar.gz langsung menimpa folder pterodactyl
    # -x: extract, -z: gzip, -v: verbose, -f: file
    tar -xzvf "$FILE_PATH" -C /var/www/pterodactyl
    
    # Hapus file mentahan biar bersih
    rm "$FILE_PATH"
    
    # Fix permission (Penting biar gak error 500)
    chmod -R 755 /var/www/pterodactyl
    chown -R www-data:www-data /var/www/pterodactyl
    
    echo -e "${GREEN}Ekstrak selesai.${RESET}"
else
    echo -e "${RED}Gagal download! Cek linknya bro.${RESET}"
    exit 1
fi

# -------------------------------------------------------
# 3. BUILD PANEL
# -------------------------------------------------------
echo -e "${YELLOW}[3/4] Membuild Panel...${RESET}"

cd /var/www/pterodactyl || exit
yarn

# Set flag OpenSSL (Wajib buat Node 16 ke atas di project lama)
export NODE_OPTIONS=--openssl-legacy-provider

# Build Production
if ! yarn build:production; then
    echo -e "${RED}Build gagal, mencoba auto-fix...${RESET}"
    yarn add react-feather
    npx update-browserslist-db@latest
    yarn build:production
fi

# -------------------------------------------------------
# 4. FINISHING
# -------------------------------------------------------
echo -e "${YELLOW}[4/4] Finishing...${RESET}"

php artisan migrate --force
php artisan view:clear
php artisan config:clear
chown -R www-data:www-data /var/www/pterodactyl

echo ""
echo -e "${BLUE}=========================================${RESET}"
echo -e "${GREEN}   STELLAR THEME BERHASIL DIINSTALL!     ${RESET}"
echo -e "${BLUE}=========================================${RESET}"
