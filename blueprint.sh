#!/bin/bash

# ==========================================
#  Blueprint Auto Installer (Anti-Error Version)
#  Special for ManzXD
#  Fixes: Tailwind Colors & Node.js SSL Legacy
# ==========================================

# Warna Terminal
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory
PTERODACTYL_DIRECTORY="/var/www/pterodactyl"

echo -e "${YELLOW}[INFO] Memulai instalasi Blueprint dengan Auto-Fix...${NC}"

# 1. Cek Folder
if [ ! -d "$PTERODACTYL_DIRECTORY" ]; then
    echo -e "${RED}[ERROR] Directory $PTERODACTYL_DIRECTORY tidak ditemukan!${NC}"
    exit 1
fi

# 2. Install Dependencies Sistem
echo -e "${YELLOW}[STEP 1/7] Menginstall dependencies sistem...${NC}"
sudo apt update -y
sudo apt install -y curl wget unzip ca-certificates git gnupg zip

# 3. Setup Node.js 20.x
echo -e "${YELLOW}[STEP 2/7] Setup Node.js repo...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update -y
sudo apt install -y nodejs

# 4. Install Yarn & Download Blueprint
echo -e "${YELLOW}[STEP 3/7] Setup Yarn & Download Blueprint...${NC}"
sudo npm i -g yarn
cd $PTERODACTYL_DIRECTORY

wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PTERODACTYL_DIRECTORY/release.zip"
unzip -o release.zip
rm release.zip

# 5. Fix Tailwind Config (Inject Warna Orange Otomatis)
echo -e "${YELLOW}[STEP 4/7] Menerapkan Fix: Menambahkan Warna Orange...${NC}"
# Hapus settingan orange lama jika ada (biar gak duplikat)
sed -i '/orange:/d' tailwind.config.js
# Masukkan full set warna orange 100-900
sed -i "/colors: {/a \                orange: { 100: '#ffedd5', 200: '#fed7aa', 300: '#fdba74', 400: '#fb923c', 500: '#f97316', 600: '#ea580c', 700: '#c2410c', 800: '#9a3412', 900: '#7c2d12' }," tailwind.config.js

# 6. Install Dependency & Build Panel (Dengan Mode Legacy)
echo -e "${YELLOW}[STEP 5/7] Menjalankan Yarn Install & Build Production...${NC}"
yarn install

# AKTIFKAN MODE LEGACY DI SINI (Kunci anti error Node 20)
export NODE_OPTIONS=--openssl-legacy-provider

# Build panel
yarn build:production

# 7. Setup Config Blueprint
echo -e "${YELLOW}[STEP 6/7] Membuat konfigurasi .blueprintrc...${NC}"
touch $PTERODACTYL_DIRECTORY/.blueprintrc
echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc
chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh

# Fix Permission Akhir
chown -R www-data:www-data $PTERODACTYL_DIRECTORY
chmod -R 755 $PTERODACTYL_DIRECTORY/storage $PTERODACTYL_DIRECTORY/bootstrap/cache

# 8. Jalankan Installer Blueprint
echo -e "${YELLOW}[STEP 7/7] Menjalankan Installer Blueprint...${NC}"
bash $PTERODACTYL_DIRECTORY/blueprint.sh

echo -e "${GREEN}[SUCCESS] Instalasi Selesai! Panel sudah di-build dengan aman.${NC}"
