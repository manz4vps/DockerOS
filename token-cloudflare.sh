#!/bin/bash

# Cloudflared Installer (Smart Menu)
# Created by ManzXD

# ==========================================
# 1. KONFIGURASI TOKEN
# ==========================================

# --- PANEL (CUMA 1 SLOT) ---
panel_man="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNDlkMTgwNWEtODc2MS00MWRiLWI1ZTYtYTEyZGJiMWQ4N2U0IiwicyI6Ik0ySXhNbUUyWm1VdE1UWXhNUzAwTWprMExXSmtOVGN0TVdNeU9HTm1PREJrT0RReCJ9"
panel_din="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOThlNjIyNTEtNzUxNS00MjIyLWEyZTQtMzAxNWFhMzg4NmI2IiwicyI6IllqQXpOREUzWVRBdE5HSmlNeTAwTkdGaUxXSTVPVGt0TVdKaU56SXlPVEl6WW1NNSJ9"

# --- NODE MANZ (10 SLOT) ---
# Isi token di sini (man1, man2, dst...)
man1="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiYzhmODFlMmYtNDRiMi00ZGY3LWI4MGMtMDZlODEwMTdiOWU3IiwicyI6Ill6YzFNamhrTVdFdE1EazVNeTAwWWpnMkxUa3hZek10TVRJNVlqTTJOakV5WldRNSJ9"
man2="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOTViYzIyMGQtNmZmNi00ODEwLWFiZTMtODgyMjdmMGRhOGMxIiwicyI6Ik9HTmlaams0TUdRdFlqUTNZeTAwWkRCa0xXSTFOR0V0WlRreE5UWmhZbUkxWlRFMyJ9"
man3="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiMzlhZDYwZTQtMzExNC00ODM4LWFiOWItZDdkYjQzMDdmMTBkIiwicyI6Ik16RTVZekV5TlRVdFl6Y3lNaTAwT0RJd0xXRXpabVF0T1dFMk1HUmtNamxpWVdJNSJ9"
man4=""
man5=""
man6=""
man7=""
man8=""
man9=""
man10=""

# --- NODE DINZ (10 SLOT) ---
# Isi token di sini (din1, din2, dst...)
din1=""
din2=""
din3=""
din4=""
din5=""
din6=""
din7=""
din8=""
din9=""
din10=""


# ==========================================
# 2. SYSTEM FUNCTIONS
# ==========================================
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fungsi Install
run_install() {
    local label=$1
    local token=$2

    if [[ -z "$token" ]]; then
        echo -e "\n${RED}[ERROR] Token untuk $label belum diisi!${NC}"
        echo -e "Silahkan edit file ini dan isi tokennya dulu."
        echo ""
        read -p "Tekan Enter untuk kembali..."
        return
    fi

    clear
    echo "==================================="
    echo -e " Processing: $label"
    echo "==================================="
    
    sudo cloudflared service uninstall >/dev/null 2>&1
    
    if sudo cloudflared service install "$token"; then
        echo -e "${GREEN}✅ [SUCCESS] $label installed.${NC}"
    else
        echo -e "${RED}❌ [ERROR] Failed. Check token.${NC}"
    fi
    echo ""
    read -p "Press Enter to exit..."
}

# Fungsi Menu Item dengan Indikator
show_menu() {
    local num=$1
    local label=$2
    local token=$3
    if [[ -z "$token" ]]; then
        echo -e " ${num}. ${label} ${RED}❌${NC}"
    else
        echo -e " ${num}. ${label}"
    fi
}

if ! command -v cloudflared &>/dev/null; then
    echo -e "${RED}Error: cloudflared is not installed.${NC}"
    exit 1
fi


# ==========================================
# 3. MENU UTAMA
# ==========================================
while true; do
    clear
    echo "==================================="
    echo "   CLOUDFLARED TUNNEL MANAGER"
    echo "==================================="
    echo " 1. Install Tunnel PANEL (Web)"
    echo " 2. Install Tunnel NODE (Wings)"
    echo " 0. Exit"
    echo "==================================="
    read -p "Pilih Kategori [1-2]: " main_opt

    case $main_opt in
        1)
            # === MENU PANEL (LANGSUNG INSTALL) ===
            clear
            echo "==================================="
            echo "      PILIH PEMILIK PANEL"
            echo "==================================="
            echo " 1. Install Panel Manz"
            echo " 2. Install Panel Dinz"
            echo " 0. Kembali"
            echo "==================================="
            read -p "Pilih [1-2]: " p_opt
            
            case $p_opt in
                1) run_install "Panel Manz" "$panel_man" ;;
                2) run_install "Panel Dinz" "$panel_din" ;;
                0) continue ;;
                *) echo "Invalid"; sleep 1 ;;
            esac
            ;;

        2)
            # === MENU NODE (PILIH OWNER DULU) ===
            clear
            echo "==================================="
            echo "      PILIH PEMILIK NODE"
            echo "==================================="
            echo " 1. Node Manz"
            echo " 2. Node Dinz"
            echo " 0. Kembali"
            echo "==================================="
            read -p "Pilih [1-2]: " n_opt
            
            case $n_opt in
                1) 
                   # LIST NODE MANZ (1-10)
                   clear; echo "=== LIST NODE MANZ ==="
                   show_menu 1 "Node Manz 1" "$man1"; show_menu 2 "Node Manz 2" "$man2"
                   show_menu 3 "Node Manz 3" "$man3"; show_menu 4 "Node Manz 4" "$man4"
                   show_menu 5 "Node Manz 5" "$man5"; show_menu 6 "Node Manz 6" "$man6"
                   show_menu 7 "Node Manz 7" "$man7"; show_menu 8 "Node Manz 8" "$man8"
                   show_menu 9 "Node Manz 9" "$man9"; show_menu 10 "Node Manz 10" "$man10"
                   echo " 0. Kembali"; echo "======================="
                   read -p "Pilih [1-10]: " opt
                   case $opt in
                       1) run_install "Node Manz 1" "$man1" ;; 2) run_install "Node Manz 2" "$man2" ;;
                       3) run_install "Node Manz 3" "$man3" ;; 4) run_install "Node Manz 4" "$man4" ;;
                       5) run_install "Node Manz 5" "$man5" ;; 6) run_install "Node Manz 6" "$man6" ;;
                       7) run_install "Node Manz 7" "$man7" ;; 8) run_install "Node Manz 8" "$man8" ;;
                       9) run_install "Node Manz 9" "$man9" ;; 10) run_install "Node Manz 10" "$man10" ;;
                       0) continue ;; *) echo "Invalid"; sleep 1 ;;
                   esac ;;

                2) 
                   # LIST NODE DINZ (1-10)
                   clear; echo "=== LIST NODE DINZ ==="
                   show_menu 1 "Node Dinz 1" "$din1"; show_menu 2 "Node Dinz 2" "$din2"
                   show_menu 3 "Node Dinz 3" "$din3"; show_menu 4 "Node Dinz 4" "$din4"
                   show_menu 5 "Node Dinz 5" "$din5"; show_menu 6 "Node Dinz 6" "$din6"
                   show_menu 7 "Node Dinz 7" "$din7"; show_menu 8 "Node Dinz 8" "$din8"
                   show_menu 9 "Node Dinz 9" "$din9"; show_menu 10 "Node Dinz 10" "$din10"
                   echo " 0. Kembali"; echo "======================="
                   read -p "Pilih [1-10]: " opt
                   case $opt in
                       1) run_install "Node Dinz 1" "$din1" ;; 2) run_install "Node Dinz 2" "$din2" ;;
                       3) run_install "Node Dinz 3" "$din3" ;; 4) run_install "Node Dinz 4" "$din4" ;;
                       5) run_install "Node Dinz 5" "$din5" ;; 6) run_install "Node Dinz 6" "$din6" ;;
                       7) run_install "Node Dinz 7" "$din7" ;; 8) run_install "Node Dinz 8" "$din8" ;;
                       9) run_install "Node Dinz 9" "$din9" ;; 10) run_install "Node Dinz 10" "$din10" ;;
                       0) continue ;; *) echo "Invalid"; sleep 1 ;;
                   esac ;;
                0) continue ;;
            esac
            ;;

        0) exit 0 ;;
        *) echo "Menu tidak valid."; sleep 1 ;;
    esac
done
