#!/bin/bash

# ==========================================
# PTERODACTYL ADDON INSTALLER (8 BLUEPRINT)
# Created by ManzXD
# ==========================================

# 1. Definisi Warna & Formatting
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
    echo -e "${YELLOW}       AUTO INSTALLER ADDON PANEL       ${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo -e "        ${TEBAL}Created by ManzXD${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo ""
}

# 3. Fungsi Utama Install Addon
install_addon_panel() {
    # Cek apakah command blueprint terinstall
    if ! command -v blueprint &> /dev/null; then
        echo -e "${RED}[ERROR] Blueprint Framework belum terinstall!${RESET}"
        echo "Silakan install framework 'blueprint' terlebih dahulu."
        exit 1
    fi

    banner
    echo -e "${TEBAL}=== INSTALL ADDON PANEL (8 ADDON) ===${RESET}"
    
    # Cek Direktori Pterodactyl
    if [ -d "/var/www/pterodactyl" ]; then
        cd /var/www/pterodactyl || return
    else
        echo -e "${RED}[ERROR] Folder /var/www/pterodactyl tidak ditemukan.${RESET}"
        exit 1
    fi

    # Daftar Addon
    addons=(
        mcplugins.blueprint
        minecraftplayermanager.blueprint
        loader.blueprint
        serverbackgrounds.blueprint
        simplefavicons.blueprint
        startupchanger.blueprint
        subdomains.blueprint
        versionchanger.blueprint
    )

    # Loop Install
    for addon in "${addons[@]}"; do
        echo -e "\n${YELLOW}🔄 Processing: ${CYAN}$addon${RESET}..."
        
        # Download File
        if curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/$addon"; then
            
            # Jalankan Blueprint Install
            # Gunakan bash -c agar command blueprint terbaca env-nya jika perlu
            if blueprint -i "$addon"; then
                echo -e "${GREEN}✅ Sukses install: $addon${RESET}"
                # Hapus file blueprint setelah install biar storage ga penuh
                rm -f "$addon"
            else
                echo -e "${RED}❌ Gagal install: $addon (Cek log blueprint)${RESET}"
            fi
        else
            echo -e "${RED}❌ Gagal download: $addon (File tidak ada di repo)${RESET}"
        fi
    done

    echo -e "\n${GREEN}==========================================${RESET}"
    echo -e "${TEBAL}SEMUA ADDON TELAH DIINSTALL!${RESET}"
    echo -e "${GREEN}==========================================${RESET}"
    read -p "Tekan Enter untuk keluar..."
}

# 4. Eksekusi Fungsi
install_addon_panel
