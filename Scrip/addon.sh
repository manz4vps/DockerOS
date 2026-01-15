#!/bin/bash

# ==========================================
# PTERODACTYL ADDON INSTALLER (SELECTABLE)
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
    echo -e "${YELLOW}       AUTO INSTALLER ADDON PANEL       ${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo -e "        ${TEBAL}Created by ManzXD${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo ""
}

# 3. Fungsi Helper Install Satu Addon
install_single_addon() {
    local addon_file="$1"
    
    echo -e "\n${YELLOW}🔄 Processing: ${CYAN}$addon_file${RESET}..."
    
    # Download File
    if curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/$addon_file"; then
        # Install via Blueprint
        if blueprint -i "$addon_file"; then
            echo -e "${GREEN}✅ Sukses install: $addon_file${RESET}"
            rm -f "$addon_file" # Hapus file mentahan
        else
            echo -e "${RED}❌ Gagal install (Blueprint Error): $addon_file${RESET}"
        fi
    else
        echo -e "${RED}❌ Gagal download: $addon_file${RESET}"
    fi
    
    echo ""
    read -p "Tekan Enter untuk lanjut..."
}

# 4. Fungsi Utama Menu Addon
install_addon_panel() {
    # Cek Blueprint
    if ! command -v blueprint &> /dev/null; then
        echo -e "${RED}[ERROR] Blueprint Framework belum terinstall!${RESET}"
        exit 1
    fi

    # Cek Direktori
    if [ -d "/var/www/pterodactyl" ]; then
        cd /var/www/pterodactyl || return
    else
        echo -e "${RED}[ERROR] Folder Pterodactyl tidak ditemukan.${RESET}"
        exit 1
    fi

    # Daftar Addon (Array)
    addons=(
        "mcplugins.blueprint"               # 1
        "minecraftplayermanager.blueprint"  # 2
        "loader.blueprint"                  # 3
        "serverbackgrounds.blueprint"       # 4
        "simplefavicons.blueprint"          # 5
        "startupchanger.blueprint"          # 6
        "subdomains.blueprint"              # 7
        "versionchanger.blueprint"          # 8
    )

    while true; do
        banner
        echo -e "${TEBAL}PILIH ADDON YANG MAU DIINSTALL:${RESET}"
        echo -e "${CYAN}[1]${RESET} MC Plugins"
        echo -e "${CYAN}[2]${RESET} MC Player Manager"
        echo -e "${CYAN}[3]${RESET} Loader (Loading Screen)"
        echo -e "${CYAN}[4]${RESET} Server Backgrounds"
        echo -e "${CYAN}[5]${RESET} Simple Favicons"
        echo -e "${CYAN}[6]${RESET} Startup Changer"
        echo -e "${CYAN}[7]${RESET} Subdomains"
        echo -e "${CYAN}[8]${RESET} Version Changer"
        echo -e "${CYAN}----------------------------------${RESET}"
        echo -e "${GREEN}[9] 🔥 INSTALL SEMUA (ALL 8 ADDONS)${RESET}"
        echo -e "${RED}[0] 🔙 KEMBALI${RESET}"
        echo ""
        read -p "Masukkan Pilihan [0-9]: " opt

        case $opt in
            1|2|3|4|5|6|7|8)
                # Ambil nama file dari array (index dimulai dari 0, jadi dikurang 1)
                target_addon="${addons[$((opt-1))]}"
                install_single_addon "$target_addon"
                ;;
            9)
                echo -e "\n${YELLOW}🚀 GASKEUN INSTALL SEMUA...${RESET}"
                for item in "${addons[@]}"; do
                    # Kita copas logika install di sini biar jalan otomatis tanpa pause per file
                    echo -e "${CYAN}>> Menginstall $item...${RESET}"
                    curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/$item"
                    blueprint -i "$item"
                    rm -f "$item"
                done
                echo -e "\n${GREEN}✅ SEMUA ADDON TELAH DIINSTALL!${RESET}"
                read -p "Tekan Enter untuk kembali..."
                ;;
            0)
                echo -e "${GREEN}Oke, kembali...${RESET}"
                break
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${RESET}"
                sleep 1
                ;;
        esac
    done
}

# 5. Eksekusi
install_addon_panel
