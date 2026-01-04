#!/bin/bash

# ==========================================
#  Blueprint Auto Installer Script
#  Fixed & Optimized for ManzXD
# ==========================================

# Warna biar ganteng
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Variable Directory
PTERODACTYL_DIRECTORY="/var/www/pterodactyl"

echo -e "${YELLOW}[INFO] Memulai instalasi Blueprint...${NC}"

# 1. Cek apakah folder pterodactyl ada
if [ ! -d "$PTERODACTYL_DIRECTORY" ]; then
    echo -e "${RED}[ERROR] Directory $PTERODACTYL_DIRECTORY tidak ditemukan!${NC}"
    exit 1
fi

# 2. Update dan Install Dependencies Dasar (Auto Yes)
echo -e "${YELLOW}[STEP 1/6] Menginstall dependencies sistem...${NC}"
sudo apt update -y
sudo apt install -y curl wget unzip ca-certificates git gnupg zip

# 3. Setup Node.js 20.x (Auto Yes)
echo -e "${YELLOW}[STEP 2/6] Setup Node.js repo...${NC}"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list

sudo apt update -y
sudo apt install -y nodejs

# 4. Install Yarn Global
echo -e "${YELLOW}[STEP 3/6] Menginstall Yarn...${NC}"
sudo npm i -g yarn

# 5. Download & Extract Blueprint
echo -e "${YELLOW}[STEP 4/6] Download Blueprint release terbaru...${NC}"
cd $PTERODACTYL_DIRECTORY

# Download latest release
wget "$(curl -s https://api.github.com/repos/BlueprintFramework/framework/releases/latest | grep 'browser_download_url' | grep 'release.zip' | cut -d '"' -f 4)" -O "$PTERODACTYL_DIRECTORY/release.zip"

# Unzip (Overwrite without asking)
unzip -o release.zip
rm release.zip

# 6. Install Yarn Dependencies (Sesuai Request)
echo -e "${YELLOW}[STEP 5/6] Menjalankan yarn install...${NC}"
yarn install

# 7. Setup Config Blueprint (.blueprintrc)
echo -e "${YELLOW}[STEP 6/6] Membuat konfigurasi .blueprintrc...${NC}"
touch $PTERODACTYL_DIRECTORY/.blueprintrc

# Isi config otomatis
echo 'WEBUSER="www-data";
OWNERSHIP="www-data:www-data";
USERSHELL="/bin/bash";' > $PTERODACTYL_DIRECTORY/.blueprintrc

# Beri izin execute
chmod +x $PTERODACTYL_DIRECTORY/blueprint.sh

# Fix permission folder biar gak error 500 sebelum install
chown -R www-data:www-data $PTERODACTYL_DIRECTORY
chmod -R 755 $PTERODACTYL_DIRECTORY/storage $PTERODACTYL_DIRECTORY/bootstrap/cache

echo -e "${GREEN}[SUCCESS] Persiapan selesai! Menjalankan installer Blueprint sekarang...${NC}"
echo -e "${YELLOW}Catatan: Jika installer meminta input, silakan ketik manual.${NC}"

# Jalankan script blueprint
bash $PTERODACTYL_DIRECTORY/blueprint.sh
