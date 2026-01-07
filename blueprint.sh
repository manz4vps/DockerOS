#!/bin/bash

# ==========================================
#  Blueprint Auto Installer (Ultimate Fix)
#  Special for ManzXD
#  Fixes: Tailwind, Axios, & React Route Error
# ==========================================

# Warna Terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory
PTERODACTYL_DIRECTORY="/var/www/pterodactyl"

# Fungsi Error Handling
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}[ERROR] Terjadi kesalahan pada langkah: $1${NC}"
        exit 1
    fi
}

echo -e "${YELLOW}[INFO] Memulai instalasi Blueprint Ultimate Fix...${NC}"

# 1. Cek Folder
if [ ! -d "$PTERODACTYL_DIRECTORY" ]; then
    echo -e "${RED}[ERROR] Directory $PTERODACTYL_DIRECTORY tidak ditemukan!${NC}"
    exit 1
fi

# 2. Install Dependencies Sistem
echo -e "${YELLOW}[STEP 1/9] Menginstall dependencies sistem...${NC}"
sudo apt update -y
sudo apt install -y curl wget unzip ca-certificates git gnupg zip
check_error "Install Dependencies"

# 3. Setup Node.js 20.x
echo -e "${YELLOW}[STEP 2/9] Setup Node.js repo...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update -y
sudo apt install -y nodejs
check_error "Install Node.js"

# 4. Setup Yarn & Download Blueprint
echo -e "${YELLOW}[STEP 3/9] Setup Yarn & Download Blueprint...${NC}"
npm i -g yarn
cd $PTERODACTYL_DIRECTORY

# Hapus file release lama jika ada
rm -f release.zip
wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PTERODACTYL_DIRECTORY/release.zip"
unzip -o release.zip
rm release.zip
check_error "Download Blueprint"

# 5. Fix Tailwind Config
echo -e "${YELLOW}[STEP 4/9] Menerapkan Fix Warna Orange...${NC}"
sed -i '/orange:/d' tailwind.config.js
sed -i "/colors: {/a \                orange: { 100: '#ffedd5', 200: '#fed7aa', 300: '#fdba74', 400: '#fb923c', 500: '#f97316', 600: '#ea580c', 700: '#c2410c', 800: '#9a3412', 900: '#7c2d12' }," tailwind.config.js

# 6. BERSIH-BERSIH & INSTALL AWAL
echo -e "${YELLOW}[STEP 5/9] Membersihkan cache dan install dependencies awal...${NC}"
rm -rf node_modules yarn.lock
yarn cache clean
yarn install
check_error "Yarn Install Awal"

# 7. PATCH KHUSUS (INI YANG PENTING!)
echo -e "${YELLOW}[STEP 6/9] Melakukan Patching React Types & Axios...${NC}"

# Fix 1: Paksa Axios terbaru (Supaya file upload jalan)
yarn add axios

# Fix 2: Turunkan versi @types/react ke v17 (Supaya Error 'Route' hilang)
# Kita hapus dulu yang v18, lalu pasang v17
yarn remove @types/react @types/react-dom
yarn add -D @types/react@17.0.39 @types/react-dom@17.0.17

check_error "Patching Dependencies"

# 8. Build Panel
echo -e "${YELLOW}[STEP 7/9] Menjalankan Build Production...${NC}"
export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production
check_error "Yarn Build Production"

# 9. Setup Config Blueprint
echo -e "${YELLOW}[STEP 8/9] Membuat konfigurasi .blueprintrc...${NC}"
touch $PTERODACTYL_DIRECTORY/.blueprintrc
echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc
chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh

# Fix Permission Akhir
chown -R www-data:www-data $PTERODACTYL_DIRECTORY
chmod -R 755 $PTERODACTYL_DIRECTORY/storage $PTERODACTYL_DIRECTORY/bootstrap/cache

# Jalankan Installer Blueprint
echo -e "${YELLOW}[FINAL] Menjalankan Installer Blueprint...${NC}"
bash $PTERODACTYL_DIRECTORY/blueprint.sh
check_error "Blueprint Installer"

echo -e "${GREEN}[SUCCESS] MANTAP! Instalasi Selesai & Build Sukses.${NC}"
