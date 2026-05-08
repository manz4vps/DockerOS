#!/bin/bash

# ==========================================
# PTERODACTYL ADDON INSTALLER (DIRECT LINK)
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
    echo -e "${YELLOW}        AUTO INSTALLER ADDON PANEL        ${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo -e "         ${TEBAL}Created by ManzXD${RESET}"
    echo -e "${CYAN}==========================================${RESET}"
    echo ""
}

# 3. Fungsi Install Langsung (Pake Link & Nama File)
install_direct() {
    local url="$1"
    local filename="$2"
    
    echo -e "\n${YELLOW}🔄 Sedang mendownload: ${CYAN}$filename${RESET}..."
    
    # Download File menggunakan Link Langsung
    # -L untuk follow redirect, -o untuk simpan dengan nama tertentu
    if curl -L -o "$filename" "$url"; then
        echo -e "${GREEN}⬇️ Download selesai. Menginstall blueprint...${RESET}"
        
        # Install via Blueprint
        if blueprint -i "$filename"; then
            echo -e "${GREEN}✅ Sukses install: $filename${RESET}"
            rm -f "$filename" # Hapus file mentahan
        else
            echo -e "${RED}❌ Gagal install (Blueprint Error): $filename${RESET}"
            # Jangan hapus file kalau error, biar bisa dicek manual
        fi
    else
        echo -e "${RED}❌ Gagal download dari link tersebut!${RESET}"
    fi
    
    echo ""
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
        echo -e "${CYAN}[9]${RESET} HuxRegister"
        echo -e "${CYAN}----------------------------------${RESET}"
        echo -e "${GREEN}[10] 🔥 INSTALL SEMUA (ALL 9 ADDONS)${RESET}"
        echo -e "${RED}[0] 🔙 KEMBALI${RESET}"
        echo ""
        
        # TIPS CARA PAKAI BARU
        echo -e "${YELLOW}Tips: Bisa pilih banyak sekaligus, pisahkan dengan spasi.${RESET}"
        echo -e "${YELLOW}Contoh: 1 4 5${RESET}"
        read -p "Masukkan Pilihan: " opts

        # Menggunakan perulangan (looping) agar bisa memproses lebih dari 1 pilihan
        for opt in $opts; do
            case $opt in
                1)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/mcplugins.blueprint"
                    FILE="mcplugins.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                2)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/sagaminecraftplayermanager.blueprint"
                    FILE="sagaminecraftplayermanager.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                3)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/loader.blueprint"
                    FILE="loader.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                4)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/serverbackgrounds.blueprint"
                    FILE="serverbackgrounds.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                5)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/simplefavicons.blueprint"
                    FILE="simplefavicons.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                6)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/startupchanger.blueprint"
                    FILE="startupchanger.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                7)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/subdomains.blueprint"
                    FILE="subdomains.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                8)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/versionchanger.blueprint"
                    FILE="versionchanger.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                9)
                    LINK="https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/huxregister.blueprint"
                    FILE="huxregister.blueprint"
                    install_direct "$LINK" "$FILE"
                    ;;
                10)
                    echo -e "\n${YELLOW}🚀 GASKEUN INSTALL SEMUA...${RESET}"
                    
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/mcplugins.blueprint" "mcplugins.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/sagaminecraftplayermanager.blueprint" "sagaminecraftplayermanager.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/loader.blueprint" "loader.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/serverbackgrounds.blueprint" "serverbackgrounds.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/simplefavicons.blueprint" "simplefavicons.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/startupchanger.blueprint" "startupchanger.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/subdomains.blueprint" "subdomains.blueprint"
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/versionchanger.blueprint" "versionchanger.blueprint"
                    # Tambahan parameter nama file yang tertinggal di script aslimu
                    install_direct "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/Scrip/huxregister.blueprint" "huxregister.blueprint"
                    
                    echo -e "\n${GREEN}✅ SEMUA PROSES SELESAI!${RESET}"
                    ;;
                0)
                    echo -e "${GREEN}Oke, kembali...${RESET}"
                    break 2 # Keluar dari for loop dan while loop sekaligus
                    ;;
                *)
                    echo -e "${RED}Pilihan [$opt] tidak valid! Dilewati...${RESET}"
                    sleep 1
                    ;;
            esac
        done
        
        # Minta Enter di akhir aja setelah semua addon yang dipilih beres diinstall
        if [[ "$opts" != "0" ]]; then
            echo ""
            read -p "Tekan Enter untuk lanjut/kembali ke menu..."
        fi
    done
}

# 5. Eksekusi
install_addon_panel
