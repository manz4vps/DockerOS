#!/bin/bash

# ==================================================
# AUTO INSTALLER ARIX THEME v1.3.1 - MANZ4VPS
# ==================================================

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'
BOLD='\033[1m'

PTERO_DIR="/var/www/pterodactyl"

# Cek Akses Root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan sebagai root (gunakan sudo -i).${RESET}" 
   exit 1
fi

# Cek Folder Pterodactyl
if [ ! -d "$PTERO_DIR" ]; then
    echo -e "${RED}Folder Pterodactyl ($PTERO_DIR) tidak ditemukan.${RESET}"
    exit 1
fi

clear
echo -e "${CYAN}======================================================${RESET}"
echo -e "${GREEN}${BOLD}     AUTO INSTALLER ARIX THEME v1.3.1 | BY MANZXD    ${RESET}"
echo -e "${CYAN}======================================================${RESET}"
echo -e "${YELLOW}Pastikan panel sudah di-rescue/default sebelum lanjut!${RESET}\n"

cd "$PTERO_DIR" || exit

echo -e "${CYAN}[1/6] Mendownload file Arix v1.3.1 dari GitHub...${RESET}"
DOWNLOAD_URL="https://raw.githubusercontent.com/manz4vps/DockerOS/main/Scrip/arix-v1.3.1.zip"
wget -qO arix-v1.3.1.zip "$DOWNLOAD_URL"

if [ ! -f "arix-v1.3.1.zip" ]; then
    echo -e "${RED}❌ Gagal mendownload arix-v1.3.1.zip! Cek koneksi atau link repo.${RESET}"
    exit 1
fi

echo -e "\n${CYAN}[2/6] Mengekstrak dan menyusun struktur folder...${RESET}"
apt-get install -y unzip > /dev/null 2>&1
unzip -qo arix-v1.3.1.zip

if [ -d "pterodactyl" ]; then
    cp -r pterodactyl/* ./
fi

rm -rf pterodactyl unlocked-docs-page readme.html readme.md readme.txt arix-v1.3.1.zip

echo -e "\n${CYAN}[3/6] Memastikan NodeJS & Yarn terinstall...${RESET}"
apt-get install -y curl > /dev/null 2>&1
curl -fsSL https://deb.nodesource.com/setup_20.x | bash - > /dev/null 2>&1
apt-get install -y nodejs > /dev/null 2>&1
npm i -g yarn > /dev/null 2>&1
yarn install > /dev/null 2>&1

echo -e "\n${CYAN}[4/6] Menjalankan Instalasi & Build Arix (PROSES LAMA)...${RESET}"
echo -e "${YELLOW}⚠️ Jangan tutup terminal, tunggu sampai proses selesai! ⚠️${RESET}"
export NODE_OPTIONS=--openssl-legacy-provider 
# INI YANG BENER: langsung eksekusi install biar auto build
echo -e "yes\n0" | php artisan arix install

echo -e "\n${CYAN}[5/6] Memastikan database & cache sinkron...${RESET}"
php artisan migrate --force
php artisan view:clear
php artisan optimize:clear
php artisan optimize

echo -e "\n${CYAN}[6/6] Memperbaiki perizinan file (Fix Error 500 Nginx/Apache)...${RESET}"
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 storage bootstrap/cache

echo -e "\n${GREEN}======================================================${RESET}"
echo -e "${GREEN}${BOLD}✅ INSTALASI TEMA ARIX v1.3.1 SELESAI!${RESET}"
echo -e "${GREEN}======================================================${RESET}"
echo -e "Silakan refresh website panel Pterodactyl kamu bro."
echo -e "Have a good day! 🚀\n"
