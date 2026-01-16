#!/bin/bash

# =======================================================
#  INSTALLER KHUSUS THEME STELLAR (PTERODACTYL)
#  Extracted for: User Request
# =======================================================

# Definisi Warna
RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'

# Cek apakah dijalankan di root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Script ini harus dijalankan sebagai root (sudo).${RESET}" 
   exit 1
fi

# Cek direktori Pterodactyl
if [ ! -d "/var/www/pterodactyl" ]; then
    echo -e "${RED}Direktori /var/www/pterodactyl tidak ditemukan.${RESET}"
    exit 1
fi

clear
echo -e "${BLUE}=========================================${RESET}"
echo -e "${YELLOW}    MEMULAI INSTALASI THEME STELLAR      ${RESET}"
echo -e "${BLUE}=========================================${RESET}"
echo ""

# -------------------------------------------------------
# 1. SETUP DEPENDENCIES (NODEJS & YARN)
# -------------------------------------------------------
echo -e "${YELLOW}[1/4] Memeriksa dan menginstall Dependencies...${RESET}"

# Setup Keyrings
if [ ! -d "/etc/apt/keyrings" ]; then
  mkdir -p /etc/apt/keyrings
fi

# Cek & Install Node.js (Target Node 16.x sesuai script asli)
if ! command -v node &> /dev/null; then
    echo "Menginstall Node.js..."
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_16.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
    sudo apt update
    sudo apt install -y nodejs
else
    echo "Node.js sudah terinstall."
fi

# Cek & Install Yarn
if ! command -v yarn &> /dev/null; then
    echo "Menginstall Yarn..."
    npm i -g yarn
else
    echo "Yarn sudah terinstall."
fi

# Install paket tambahan yang sering dibutuhkan
sudo apt install -y unzip git curl

# -------------------------------------------------------
# 2. DOWNLOAD & EXTRACT FILES
# -------------------------------------------------------
echo -e "${YELLOW}[2/4] Mendownload file tema...${RESET}"

# URL Repo (Sesuai script asli)
REPO_URL="https://github.com/manz4vps/DockerOS/edit/main/Scrip/theme-stellar.zip"
TEMP_DIR="temp_stellar_install"

cd /var/www || exit
wget "$REPO_URL" "$TEMP_DIR"

if [ -f "/var/www/$TEMP_DIR/theme-stellar.zip" ]; then
    echo "File ditemukan, mengekstrak..."
    mv "/var/www/$TEMP_DIR/theme-stellar.zip" /var/www/
    unzip -o /var/www/theme-stellar.zip -d /var/www/
    rm /var/www/theme-stellar.zip
    rm -rf "/var/www/$TEMP_DIR"
else
    echo -e "${RED}Gagal mendownload file tema. Cek koneksi atau repo.${RESET}"
    rm -rf "/var/www/$TEMP_DIR"
    exit 1
fi

# -------------------------------------------------------
# 3. BUILD PANEL (YARN BUILD)
# -------------------------------------------------------
echo -e "${YELLOW}[3/4] Membuild Panel (Ini mungkin memakan waktu)...${RESET}"

cd /var/www/pterodactyl || exit

# Install dependencies project
yarn

# Set flag OpenSSL legacy provider untuk kompatibilitas Node terbaru dengan Webpack lama
export NODE_OPTIONS=--openssl-legacy-provider

# Coba Build Production
if ! yarn build:production; then
  echo -e "${RED}Build pertama gagal, mencoba perbaikan otomatis...${RESET}"
  
  # Langkah perbaikan sesuai script asli (fix react-feather error)
  yarn add react-feather
  npx update-browserslist-db@latest
  
  # Coba build lagi
  export NODE_OPTIONS=--openssl-legacy-provider
  if yarn build:production; then
      echo -e "${GREEN}Build berhasil setelah perbaikan.${RESET}"
  else
      echo -e "${RED}Build gagal total. Silakan cek log error.${RESET}"
      exit 1
  fi
else
  echo -e "${GREEN}Build berhasil.${RESET}"
fi

# -------------------------------------------------------
# 4. FINISHING (MIGRATE & CLEAR CACHE)
# -------------------------------------------------------
echo -e "${YELLOW}[4/4] Membersihkan Cache...${RESET}"

php artisan migrate --force
php artisan view:clear
php artisan config:clear

echo ""
echo -e "${BLUE}=========================================${RESET}"
echo -e "${GREEN}   THEME STELLAR BERHASIL DIINSTALL!     ${RESET}"
echo -e "${BLUE}=========================================${RESET}"
