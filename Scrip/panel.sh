#!/bin/bash

# Warna biar enak dilihat
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Bersihin layar dulu
clear

# Header Logo/Judul
echo -e "${GREEN}=============================================${NC}"
echo -e "${CYAN}          DOCKER OS MANAGER v1.0             ${NC}"
echo -e "${YELLOW}       Powered by manz4vps | DockerOS        ${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""

# Fungsi Install Panel
function install_panel() {
    echo -e "${CYAN}[+] Mempersiapkan Instalasi Panel...${NC}"
    sleep 1
    # Menjalankan script menggunakan curl
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-panel.sh)
}

# Fungsi Downgrade
function downgrade_ver() {
    echo -e "${CYAN}[+] Memulai Proses Downgrade...${NC}"
    sleep 1
    # Menjalankan script menggunakan curl
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/downgrate.sh)
}

# Menu Utama
echo -e "Silakan pilih menu:"
echo -e "${GREEN}[1]${NC} Install Panel"
echo -e "${GREEN}[2]${NC} Downgrade Version"
echo -e "${RED}[0]${NC} Keluar"
echo ""
read -p "Masukkan pilihan (0-2): " choice

case $choice in
    1)
        install_panel
        ;;
    2)
        downgrade_ver
        ;;
    0)
        echo -e "${RED}Keluar dari script...${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}Pilihan tidak valid bro!${NC}"
        exit 1
        ;;
esac
