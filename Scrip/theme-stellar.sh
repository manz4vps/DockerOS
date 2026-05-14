#!/bin/bash
# ==================================================
# STELLAR THEME AUTO INSTALLER (MANZ-FIXED)
# Based on User Experience (Bug Fixes & Optimized)
# ==================================================

# ---------------- CEK ROOT ----------------
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[1;31mSTOP! Harus Run as Root (sudo -i)\e[0m"
  exit 1
fi

# ---------------- WARNA & UI ----------------
MERAH="\033[31m"
HIJAU="\033[32m"
KUNING="\033[33m"
BIRU="\033[34m"
RESET="\033[0m"

banner(){
clear
echo -e "${BIRU}=============================================${RESET}"
echo -e "${HIJAU}    STELLAR THEME INSTALLER | BY MANZXD    ${RESET}"
echo -e "${BIRU}=============================================${RESET}"
echo -e "${KUNING}⚡ Fitur: Auto Build, Bug Fix, Anti Error 500${RESET}"
sleep 2
}

step(){ echo -e "\n${BIRU}➜ $1${RESET}"; }

# ---------------- MULAI ----------------
banner

# 1. DOWNLOAD & EKSTRAK TEMA
step "Mendownload & Mengekstrak Tema..."
# Pindah langsung ke folder panel
cd /var/www/pterodactyl 

# Hapus file lama jika ada
rm -f Stellar-v3.4.1.zip
wget -O Stellar-v3.4.1.zip "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/Stellar-v3.4.1.zip"

echo -e "${KUNING}Mengekstrak file...${RESET}"
unzip -o Stellar-v3.4.1.zip
# Langsung hapus file zip setelah diekstrak biar storage nggak penuh
rm -f Stellar-v3.4.1.zip

# 2. INSTALL NODEJS & YARN
step "Menginstall NodeJS & Yarn..."
apt-get install -y curl

# Menggunakan Node 20.x karena terbukti paling stabil untuk build Pterodactyl saat ini
curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
apt-get install -y nodejs
npm install -g yarn

# 3. PERSIAPAN BUILD (FIX BUG & DEPENDENCIES)
step "Memperbaiki Bug Codingan & Install Library..."
yarn add react-feather

echo -e "${KUNING}Memperbaiki bug VariableBox.tsx...${RESET}"
# Cek apakah file ada sebelum meniban code untuk menghindari pesan error
if [ -f "resources/scripts/components/server/startup/VariableBox.tsx" ]; then
    sed -i 's/defaultValue={variable.serverValue}/defaultValue={variable.serverValue || ""}/g' resources/scripts/components/server/startup/VariableBox.tsx
fi

# 4. PROSES BUILD
step "Membangun Aset (Build Production)..."
echo -e "${KUNING}Proses ini agak lama, tunggu saja...${RESET}"

export NODE_OPTIONS=--openssl-legacy-provider
yarn build:production

# 5. FINALISASI (DATABASE & PERMISSION)
step "Membersihkan Error 500 & Fix Database..."
php artisan migrate --force
php artisan view:clear
php artisan config:clear

# Fix Izin File (Permission) secara keseluruhan tanpa melupakan hidden file seperti .env
chown -R www-data:www-data /var/www/pterodactyl
chmod -R 755 storage bootstrap/cache

# ---------------- SELESAI ----------------
echo -e "\n${HIJAU}=============================================${RESET}"
echo -e "${HIJAU}✅ TEMA BERHASIL TERPASANG!${RESET}"
echo -e "${HIJAU}=============================================${RESET}"
echo -e "Silakan cek Panel Pterodactyl kamu."
echo -e "🎉 Terima kasih sudah menggunakan script ini!!"
echo -e "${BIRU}=============================================${RESET}"
