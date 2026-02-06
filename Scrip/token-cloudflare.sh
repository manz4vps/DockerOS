#!/bin/bash

# Cloudflared Installer (Tunnel Version)
# Modified request by User | Created by ManzXD

# ==========================================
# 1. KONFIGURASI TOKEN TUNNEL
# ==========================================

# --- TUNNEL MANZ ---
tun_man="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNDlkMTgwNWEtODc2MS00MWRiLWI1ZTYtYTEyZGJiMWQ4N2U0IiwicyI6Ik0ySXhNbUUyWm1VdE1UWXhNUzAwTWprMExXSmtOVGN0TVdNeU9HTm1PREJrT0RReCJ9"
tun_man_qzz="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNTJhOWRjM2UtMzhiOC00MWYyLTk1N2UtN2Y1NTNlNDgyNzc1IiwicyI6IllUa3pPRGhsWW1JdE5EUTFNUzAwWVdNeExXSTBOalV0WmpaaE1XTmxNV1EwWVRBdyJ9"

# --- TUNNEL DINZ ---
tun_din="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOThlNjIyNTEtNzUxNS00MjIyLWEyZTQtMzAxNWFhMzg4NmI2IiwicyI6IllqQXpOREUzWVRBdE5HSmlNeTAwTkdGaUxXSTVPVGt0TVdKaU56SXlPVEl6WW1NNSJ9"
tun_din_qzz="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiZTNiYzY1ZTItOGNlMi00NzU3LTkxOTctMmZiYWI3OGRhZDZjIiwicyI6IlptUXdOakl6TnpBdFpUa3hZaTAwWlRCa0xUa3pOREV0TURKak9XWmtOVEZqT1dFeSJ9"


# ==========================================
# 2. SYSTEM FUNCTIONS & COLORS
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

header() {
    clear
    echo -e "${CYAN}==========================================${NC}"
    echo -e "${WHITE}      CLOUDFLARED TUNNEL MANAGER${NC}"
    echo -e "${CYAN}==========================================${NC}"
}

# Fungsi Install (Return 0 jika sukses, 1 jika gagal)
run_install() {
    local label=$1
    local token=$2

    if [[ -z "$token" ]]; then
        echo -e "\n${RED}❌ [ERROR] Token untuk $label belum diisi!${NC}"
        echo -e "${YELLOW}Silahkan edit file ini dan isi tokennya dulu.${NC}"
        echo ""
        read -p "Tekan Enter untuk lanjut..."
        return 1
    fi

    echo -e "\n${YELLOW}🔄 Processing: $label...${NC}"
    
    # Hapus service lama jika ada
    sudo cloudflared service uninstall >/dev/null 2>&1
    
    # Install service baru
    if sudo cloudflared service install "$token"; then
        echo -e "${GREEN}✅ [SUCCESS] $label installed successfully!${NC}"
        echo -e "${CYAN}Tunnel sudah aktif.${NC}"
        echo ""
        read -p "Tekan Enter untuk kembali..."
        return 0
    else
        echo -e "${RED}❌ [ERROR] Failed to install. Token invalid.${NC}"
        echo ""
        read -p "Tekan Enter untuk mencoba lagi..."
        return 1
    fi
}

# Cek apakah cloudflared terinstall
if ! command -v cloudflared &>/dev/null; then
    echo -e "${RED}Error: cloudflared is not installed.${NC}"
    echo -e "Silahkan install cloudflared binary terlebih dahulu."
    exit 1
fi

# ==========================================
# 3. MENU UTAMA
# ==========================================
while true; do
    header
    echo -e " ${YELLOW}1.${NC} Install Tunnel ${CYAN}MANZ${NC}"
    echo -e " ${YELLOW}2.${NC} Install Tunnel ${CYAN}MANZ-QZZ${NC}"
    echo -e "${CYAN}------------------------------------------${NC}"
    echo -e " ${YELLOW}3.${NC} Install Tunnel ${CYAN}DINZ${NC}"
    echo -e " ${YELLOW}4.${NC} Install Tunnel ${CYAN}DINZ-QZZ${NC}"
    echo -e "${CYAN}------------------------------------------${NC}"
    echo -e " ${YELLOW}0.${NC} Exit / Keluar"
    echo -e "${CYAN}==========================================${NC}"
    read -p "Pilih Menu [0-4]: " main_opt

    case $main_opt in
        1)
            run_install "Tunnel Manz" "$tun_man"
            ;;
        2)
            run_install "Tunnel Manz-qzz" "$tun_man_qzz"
            ;;
        3)
            run_install "Tunnel Dinz" "$tun_din"
            ;;
        4)
            run_install "Tunnel Dinz-qzz" "$tun_din_qzz"
            ;;
        0)
            echo -e "${GREEN}Terima kasih. Bye!${NC}"
            exit 0 
            ;;
        *)
            echo -e "${RED}Pilihan tidak valid!${NC}"
            sleep 1 
            ;;
    esac
done
