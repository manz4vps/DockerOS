#!/bin/bash
# ==================================================
# STELLAR THEME AUTO INSTALLER (MANZ-FIXED)
# Based on User Experience (Node 24 + Bug Fixes)
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
echo -e "${HIJAU}      STELLAR THEME INSTALLER | BY MANZXD    ${RESET}"
echo -e "${BIRU}=============================================${RESET}"
echo -e "${KUNING}⚡ Fitur: Auto Build, Bug Fix, Anti Error 500${RESET}"
sleep 2
}

step(){ echo -e "\n${BIRU}➜ $1${RESET}"; }

# ---------------- MULAI ----------------
banner

# 1. DOWNLOAD & EKSTRAK TEMA
step "Mendownload & Mengekstrak Tema..."
cd /var/www/
# Hapus file lama kalo ada biar bersih
rm -f arix-v1.3.1.zip
# Download file dari link kamu
wget -O arix-v1.3.1.zip "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/arix-v1.3.1.zip"

# Unzip (Otomatis Timpa/Overwrite tanpa tanya 'All')
echo -e "${KUNING}Mengekstrak file...${RESET}"
unzip -o arix-v1.3.1.zip

# 2. INSTALL NODEJS & YARN
step "Menginstall NodeJS v24 & Yarn..."
cd /var/www/pterodactyl

# Cek curl
apt-get install -y curl

# Ambil NodeJS versi 24 (Sesuai request kamu)
curl -sL https://deb.nodesource.com/setup_24.x | sudo -E bash -
apt-get install -y nodejs

# Install Yarn
npm install -g yarn

# 3. PERSIAPAN BUILD (FIX BUG & DEPENDENCIES)
step "Memperbaiki Bug Codingan & Install Library..."

# Install React Feather
yarn add react-feather

# JURUS SAKTI: Fix bug 'null' pada VariableBox.tsx SEBELUM Build
# Biar pas build nanti gak merah-merah errornya
echo -e "${KUNING}Memperbaiki bug VariableBox.tsx...${RESET}"
sed -i 's/defaultValue={variable.serverValue}/defaultValue={variable.serverValue || ""}/g' resources/scripts/components/server/startup/VariableBox.tsx

# 4. PROSES BUILD
step "Membangun Aset (Build Production)..."
echo -e "${KUNING}Proses ini agak lama, tunggu saja...${RESET}"

# Aktifkan Legacy Provider biar NodeJS baru mau jalan
export NODE_OPTIONS=--openssl-legacy-provider

# Jalankan Build
yarn build:production

# 5. FINALISASI (DATABASE & PERMISSION)
step "Membersihkan Error 500 & Fix Database..."

# Update Database (PENTING)
php artisan migrate --force

# Bersihkan Cache Tampilan
php artisan view:clear
php artisan config:clear

# Fix Izin File (Permission) biar Nginx gak ngamuk
chown -R www-data:www-data /var/www/pterodactyl/*
chmod -R 755 storage/* bootstrap/cache/

# ---------------- SELESAI ----------------
echo -e "\n${HIJAU}=============================================${RESET}"
echo -e "${HIJAU}✅ TEMA BERHASIL TERPASANG!${RESET}"
echo -e "${HIJAU}=============================================${RESET}"
echo -e "Silakan cek Panel Pterodactyl kamu."
echo -e "🎉Terimakash Sudah menggunakan scrip ini!!."
echo -e "${BIRU}=============================================${RESET}"
