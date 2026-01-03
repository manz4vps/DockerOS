#!/bin/bash

# Cloudflared Installer (Smart Logic: Stay on Fail, Back on Success)
# Created by ManzXD

# ==========================================
# 1. KONFIGURASI TOKEN
# ==========================================

# --- PANEL (CUMA 1 SLOT) ---
panel_man="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNDlkMTgwNWEtODc2MS00MWRiLWI1ZTYtYTEyZGJiMWQ4N2U0IiwicyI6Ik0ySXhNbUUyWm1VdE1UWXhNUzAwTWprMExXSmtOVGN0TVdNeU9HTm1PREJrT0RReCJ9"
panel_din="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOThlNjIyNTEtNzUxNS00MjIyLWEyZTQtMzAxNWFhMzg4NmI2IiwicyI6IllqQXpOREUzWVRBdE5HSmlNeTAwTkdGaUxXSTVPVGt0TVdKaU56SXlPVEl6WW1NNSJ9"

# --- NODE MANZ (10 SLOT) ---
man1="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiYzhmODFlMmYtNDRiMi00ZGY3LWI4MGMtMDZlODEwMTdiOWU3IiwicyI6Ill6YzFNamhrTVdFdE1EazVNeTAwWWpnMkxUa3hZek10TVRJNVlqTTJOakV5WldRNSJ9"
man2="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOTViYzIyMGQtNmZmNi00ODEwLWFiZTMtODgyMjdmMGRhOGMxIiwicyI6Ik9HTmlaams0TUdRdFlqUTNZeTAwWkRCa0xXSTFOR0V0WlRreE5UWmhZbUkxWlRFMyJ9"
man3="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiMzlhZDYwZTQtMzExNC00ODM4LWFiOWItZDdkYjQzMDdmMTBkIiwicyI6Ik16RTVZekV5TlRVdFl6Y3lNaTAwT0RJd0xXRXpabVF0T1dFMk1HUmtNamxpWVdJNSJ9"
man4="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNjVjZDJlMzctOTk2MS00Yzg1LTliMzYtZGY5MmU1MWY2YmM0IiwicyI6Ik5ERXpZMlJpTUdVdFlqSTJaQzAwWVdabUxUZ3lZekl0TkRreE9ETTRNelE1TWpZMCJ9"
man5="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiM2ZhZjU4ODYtMDQxNS00Yzk5LTkyNDQtYTE2YjcxOTE4YmY1IiwicyI6Ik1HTmhObVExWlRndE5qVmhOeTAwWmpjMExXRmhNakl0TVRrek16YzNaVGhoTmpReCJ9"
man6="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiZDMyYjBhMWItNmQ1NS00MDBlLTk5NDYtNmM0NTJiZjMzNzZlIiwicyI6Ik9ESmxZelJoTldNdE5tWmhOQzAwWWpOa0xUZzNNelF0TUdObFlUbGhaalF3TXpsbSJ9"
man7="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiYmNmMTcwYjAtZjkwYS00M2Q4LTlmMjQtMjQ0Mjg5Mjk5YjkyIiwicyI6Ik0yWmhOakl3TnpjdFpqTTFaaTAwTkRBNUxUazVNbUl0TkdRd1pEUXdNMk14WTJRMSJ9"
man8="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOTE0YTkzNTUtMjllNS00NjM4LWExZDUtZjZjY2NmYjI0NDEzIiwicyI6IlptSXhPVEExWkRRdFlURXhaaTAwTkRBMExUbGpOVFl0WWpVeFpqUXhPV0ZrWkRGbSJ9"
man9="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiODMyZTE0MGEtNTljZC00NzRiLWE1MmMtNjM1MTNlZjhkNzAwIiwicyI6Ik4yRmtaVGt5WTJVdFl6WmlZUzAwTkdZMUxXSTROak10WkRNMU1qQmxaRGcyWWpjNSJ9"
man10="eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiODA4YmVlZmMtNDZlNy00ZjU5LWFhYzctMGY1NmVlMGI2ZjZhIiwicyI6IllqTmpOell5TjJFdE1tUm1PQzAwTUdWaUxUa3hOREl0WkRNelpqSTJNakJpWXprdyJ9"

# --- NODE DINZ (10 SLOT) ---
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
        return 1 # Gagal
    fi

    echo -e "\n${YELLOW}🔄 Processing: $label...${NC}"
    
    sudo cloudflared service uninstall >/dev/null 2>&1
    
    if sudo cloudflared service install "$token"; then
        echo -e "${GREEN}✅ [SUCCESS] $label installed successfully!${NC}"
        echo ""
        read -p "Tekan Enter untuk ke Menu Utama..."
        return 0 # Sukses
    else
        echo -e "${RED}❌ [ERROR] Failed to install. Token invalid.${NC}"
        echo -e "${YELLOW}(Silakan perbaiki token atau pilih node lain)${NC}"
        echo ""
        read -p "Tekan Enter untuk mencoba lagi..."
        return 1 # Gagal
    fi
}

show_menu() {
    local num=$1
    local label=$2
    local token=$3
    if [[ -z "$token" ]]; then
        echo -e " ${YELLOW}${num}.${NC} ${label} ${RED}❌${NC}"
    else
        echo -e " ${YELLOW}${num}.${NC} ${label} ${GREEN}✔${NC}"
    fi
}

if ! command -v cloudflared &>/dev/null; then
    echo -e "${RED}Error: cloudflared is not installed.${NC}"
    exit 1
fi


# ==========================================
# 3. MENU UTAMA (MAIN LOOP)
# ==========================================
while true; do
    header
    echo -e " ${YELLOW}1.${NC} Install Tunnel ${CYAN}PANEL${NC} (Web)"
    echo -e " ${YELLOW}2.${NC} Install Tunnel ${CYAN}NODE${NC} (Wings)"
    echo -e " ${YELLOW}0.${NC} Exit"
    echo -e "${CYAN}==========================================${NC}"
    read -p "Pilih Menu [0-2]: " main_opt

    case $main_opt in
        1)
            # === MENU PANEL LOOP ===
            while true; do
                header
                echo -e "           ${WHITE}MENU PANEL${NC}"
                echo -e "${CYAN}------------------------------------------${NC}"
                echo -e " ${YELLOW}1.${NC} Panel Manz"
                echo -e " ${YELLOW}2.${NC} Panel Dinz"
                echo -e " ${YELLOW}0.${NC} Kembali ke Menu Utama"
                echo -e "${CYAN}------------------------------------------${NC}"
                read -p "Pilih Panel [0-2]: " p_opt
                
                case $p_opt in
                    # Logic: Jalankan install. Jika sukses (&&), break. Jika gagal, diam di loop.
                    1) run_install "Panel Manz" "$panel_man" && break ;; 
                    2) run_install "Panel Dinz" "$panel_din" && break ;;
                    0) break ;; 
                    *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
                esac
            done
            ;;

        2)
            # === MENU NODE OWNER LOOP ===
            while true; do
                header
                echo -e "           ${WHITE}MENU NODE${NC}"
                echo -e "${CYAN}------------------------------------------${NC}"
                echo -e " ${YELLOW}1.${NC} Node Milik ${CYAN}Manz${NC}"
                echo -e " ${YELLOW}2.${NC} Node Milik ${CYAN}Dinz${NC}"
                echo -e " ${YELLOW}0.${NC} Kembali ke Menu Utama"
                echo -e "${CYAN}------------------------------------------${NC}"
                read -p "Pilih Pemilik [0-2]: " n_opt
                
                case $n_opt in
                    1) 
                       # === LIST NODE MANZ LOOP ===
                       while true; do
                           header
                           echo -e "         ${WHITE}LIST NODE MANZ${NC}"
                           echo -e "${CYAN}------------------------------------------${NC}"
                           show_menu 1 "Node Manz 1" "$man1"; show_menu 2 "Node Manz 2" "$man2"
                           show_menu 3 "Node Manz 3" "$man3"; show_menu 4 "Node Manz 4" "$man4"
                           show_menu 5 "Node Manz 5" "$man5"; show_menu 6 "Node Manz 6" "$man6"
                           show_menu 7 "Node Manz 7" "$man7"; show_menu 8 "Node Manz 8" "$man8"
                           show_menu 9 "Node Manz 9" "$man9"; show_menu 10 "Node Manz 10" "$man10"
                           echo -e "${CYAN}------------------------------------------${NC}"
                           echo -e " ${YELLOW}0.${NC} Kembali"
                           echo -e "${CYAN}==========================================${NC}"
                           read -p "Pilih Node [0-10]: " opt
                           case $opt in
                               # && break 2 artinya: Jika Sukses, keluar dari 2 loop (balik ke Main Menu)
                               # Jika Gagal, perintah break tidak jalan, jadi tetap di menu ini.
                               1) run_install "Node Manz 1" "$man1" && break 2 ;; 
                               2) run_install "Node Manz 2" "$man2" && break 2 ;;
                               3) run_install "Node Manz 3" "$man3" && break 2 ;; 
                               4) run_install "Node Manz 4" "$man4" && break 2 ;;
                               5) run_install "Node Manz 5" "$man5" && break 2 ;; 
                               6) run_install "Node Manz 6" "$man6" && break 2 ;;
                               7) run_install "Node Manz 7" "$man7" && break 2 ;; 
                               8) run_install "Node Manz 8" "$man8" && break 2 ;;
                               9) run_install "Node Manz 9" "$man9" && break 2 ;; 
                               10) run_install "Node Manz 10" "$man10" && break 2 ;;
                               0) break ;; 
                               *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
                           esac
                       done
                       ;;

                    2) 
                       # === LIST NODE DINZ LOOP ===
                       while true; do
                           header
                           echo -e "         ${WHITE}LIST NODE DINZ${NC}"
                           echo -e "${CYAN}------------------------------------------${NC}"
                           show_menu 1 "Node Dinz 1" "$din1"; show_menu 2 "Node Dinz 2" "$din2"
                           show_menu 3 "Node Dinz 3" "$din3"; show_menu 4 "Node Dinz 4" "$din4"
                           show_menu 5 "Node Dinz 5" "$din5"; show_menu 6 "Node Dinz 6" "$din6"
                           show_menu 7 "Node Dinz 7" "$din7"; show_menu 8 "Node Dinz 8" "$din8"
                           show_menu 9 "Node Dinz 9" "$din9"; show_menu 10 "Node Dinz 10" "$din10"
                           echo -e "${CYAN}------------------------------------------${NC}"
                           echo -e " ${YELLOW}0.${NC} Kembali"
                           echo -e "${CYAN}==========================================${NC}"
                           read -p "Pilih Node [0-10]: " opt
                           case $opt in
                               1) run_install "Node Dinz 1" "$din1" && break 2 ;; 
                               2) run_install "Node Dinz 2" "$din2" && break 2 ;;
                               3) run_install "Node Dinz 3" "$din3" && break 2 ;; 
                               4) run_install "Node Dinz 4" "$din4" && break 2 ;;
                               5) run_install "Node Dinz 5" "$din5" && break 2 ;; 
                               6) run_install "Node Dinz 6" "$din6" && break 2 ;;
                               7) run_install "Node Dinz 7" "$din7" && break 2 ;; 
                               8) run_install "Node Dinz 8" "$din8" && break 2 ;;
                               9) run_install "Node Dinz 9" "$din9" && break 2 ;; 
                               10) run_install "Node Dinz 10" "$din10" && break 2 ;;
                               0) break ;; 
                               *) echo -e "${RED}Pilihan salah!${NC}"; sleep 1 ;;
                           esac
                       done
                       ;;
                    
                    0) break ;; # Balik ke Menu Utama
                    *) echo -e "${RED}Pilihan tidak valid!${NC}"; sleep 1 ;;
                esac
            done
        
    ;;

        0) 
            echo -e "${GREEN}Terima kasih. Bye!${NC}"
            exit 0 
            ;;
        *) 
            echo -e "${RED}Menu tidak valid.${NC}"; sleep 1 
            ;;
    esac
done
