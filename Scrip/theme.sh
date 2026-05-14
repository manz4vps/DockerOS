#!/bin/bash

# ==========================================
# PTERODACTYL THEME INSTALLER
# Created by ManzXD
# ==========================================

# 1. Definisi Warna
TEBAL='\033[1m'
RESET='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'

# 2. Fungsi Banner
banner() {
    clear
    echo -e "${CYAN}==========================================${RESET}"
    echo -e "${YELLOW}       INSTALLER TEMA PTERODACTYL       ${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo -e "        ${TEBAL}Created by ManzXD${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo ""
}

# 3. Fungsi Helper untuk menjalankan script eksternal
jalankan_script() {
    local url="$1"
    echo -e "\n${YELLOW}🔄 Mengunduh dan menjalankan script...${RESET}"
    
    # Teknik bash <(curl) agar tidak perlu simpan file sampah
    if bash <(curl -fsSL "$url"); then
        echo -e "${GREEN}✅ Script selesai dijalankan.${RESET}"
    else
        echo -e "${RED}❌ Gagal menjalankan script dari URL tersebut.${RESET}"
    fi
}

# 4. Fungsi Utama Pasang Tema
pasang_tema() {
    while true; do
        banner
        echo -e "${TEBAL}PILIH TEMA:${RESET}"
        echo -e " [1] Nebula Theme"
        echo -e " [2] Euphoria Theme (via Blueprint)"
        echo -e " [3] Darkenate Theme"
        echo -e " [4] Stellar Theme"
        echo -e " [5] Other Theme"
        echo -e " [6] Nook Theme"
        echo -e " [6] Arix Theme"
        echo -e " [0] Keluar"
        echo -e "${CYAN}------------------------------------------${RESET}"
        read -p "Masukkan Pilihan [0-4]: " t

        case $t in
            1)
                jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/change%20theme.sh"
                read -p "Tekan Enter untuk kembali..."
                ;;
            2)
                # Cek Blueprint dulu
                if ! command -v blueprint &> /dev/null; then
                    echo -e "\n${RED}[ERROR] Blueprint tidak terinstall!${RESET}"
                    echo "Tema Euphoria membutuhkan 'blueprint' framework."
                    read -p "Tekan Enter kembali..."
                    continue
                fi

                echo -e "\n${YELLOW}🔄 Menginstall Euphoria Theme...${RESET}"
                cd /var/www/pterodactyl || return
                
                # Download & Install
                if curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/euphoriatheme.blueprint"; then
                    blueprint -i euphoriatheme.blueprint
                    rm -f euphoriatheme.blueprint # Hapus file mentahan setelah install
                    echo -e "${GREEN}✅ Euphoria Theme berhasil diinstall.${RESET}"
                else
                    echo -e "${RED}❌ Gagal download file blueprint.${RESET}"
                fi
                read -p "Tekan Enter untuk kembali..."
                ;;
            3) 
                # Cek Blueprint dulu
                if ! command -v blueprint &> /dev/null; then
                    echo -e "\n${RED}[ERROR] Blueprint tidak terinstall!${RESET}"
                    echo "Tema Darkenate membutuhkan 'blueprint' framework."
                    read -p "Tekan Enter kembali..."
                    continue
                fi

                echo -e "\n${YELLOW}🔄 Menginstall Darkena5e Theme...${RESET}"
                cd /var/www/pterodactyl || return
                
                # Download & Install
                if curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/darkenate.blueprint"; then
                    blueprint -i darkenate.blueprint
                    rm -f darkenate.blueprint # Hapus file mentahan setelah install
                    echo -e "${GREEN}✅ Darkenate Theme berhasil diinstall.${RESET}"
                else
                    echo -e "${RED}❌ Gagal download file blueprint.${RESET}"
                fi
                read -p "Tekan Enter untuk kembali..."
                ;;
            4)  
                jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/theme-stellar.sh"
                read -p "Tekan Enter untuk kembali..."
                ;;
            5)
                jalankan_script "https://github.com/manz4vps/addon-blueprint/raw/refs/heads/main/tema/install-tema.sh"
                read -p "Tekan Enter untuk kembali..."
                ;;
            6)
                jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/NookTheme.sh"
                read -p "Tekan Enter untuk kembali..."
                ;;
            7)  
                jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/theme-arix-v1.3.1.sh"
                read -p "Tekan Enter untuk kembali..."
                ;;
            0)
                echo -e "${GREEN}Terima kasih.${RESET}"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${RESET}"
                sleep 1
                ;;
        esac
    done
}

# 5. Eksekusi Script
pasang_tema
