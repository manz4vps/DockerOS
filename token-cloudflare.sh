#!/bin/bash

# Cloudflared Installer (Full 3-Layer Menu)
# Created by ManzXD

# ==========================================
# 1. KONFIGURASI TOKEN
# ==========================================

# --- PANEL MANZ ---
panel_m="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiNDlkMTgwNWEtODc2MS00MWRiLWI1ZTYtYTEyZGJiMWQ4N2U0IiwicyI6Ik0ySXhNbUUyWm1VdE1UWXhNUzAwTWprMExXSmtOVGN0TVdNeU9HTm1PREJrT0RReCJ9"

# --- PANEL DINZ ---
panel_d="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOThlNjIyNTEtNzUxNS00MjIyLWEyZTQtMzAxNWFhMzg4NmI2IiwicyI6IllqQXpOREUzWVRBdE5HSmlNeTAwTkdGaUxXSTVPVGt0TVdKaU56SXlPVEl6WW1NNSJ9"

# --- NODE MANZ ---
node_m_1="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiYzhmODFlMmYtNDRiMi00ZGY3LWI4MGMtMDZlODEwMTdiOWU3IiwicyI6Ill6YzFNamhrTVdFdE1EazVNeTAwWWpnMkxUa3hZek10TVRJNVlqTTJOakV5WldRNSJ9"
node_m_2="sudo cloudflared service install eyJhIjoiNjkxYTIzNWIxYTFiMWYxM2E0NDdiOTUyZTUyYmVhYjUiLCJ0IjoiOTViYzIyMGQtNmZmNi00ODEwLWFiZTMtODgyMjdmMGRhOGMxIiwicyI6Ik9HTmlaams0TUdRdFlqUTNZeTAwWkRCa0xXSTFOR0V0WlRreE5UWmhZbUkxWlRFMyJ9"

# --- NODE DINZ ---
node_d_1="TOKEN_DINZ_NODE_1_DISINI"
node_d_2="TOKEN_DINZ_NODE_2_DISINI"


# ==========================================
# 2. FUNGSI INSTALLER
# ==========================================
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

install_tunnel() {
    clear
    echo "==================================="
    echo -e " Processing: $1"
    echo "==================================="
    
    sudo cloudflared service uninstall >/dev/null 2>&1
    
    if sudo cloudflared service install "$2"; then
        echo -e "${GREEN}✅ [SUCCESS] $1 installed.${NC}"
    else
        echo -e "${RED}❌ [ERROR] Failed. Check token.${NC}"
    fi
    echo ""
    read -p "Press Enter to exit..."
}

if ! command -v cloudflared &>/dev/null; then
    echo -e "${RED}Error: cloudflared is not installed.${NC}"
    exit 1
fi


# ==========================================
# 3. MENU UTAMA (LAYER 1)
# ==========================================
clear
echo "==================================="
echo "   CLOUDFLARED TUNNEL MANAGER"
echo "==================================="
echo " 1. Install Tunnel PANEL"
echo " 2. Install Tunnel NODE (Wings)"
echo " 0. Exit"
echo "==================================="
read -p "Pilih Kategori [1-2]: " main_opt

case $main_opt in
    1)
        # ==========================================
        # LAYER 2: PILIH PEMILIK PANEL
        # ==========================================
        clear
        echo "==================================="
        echo "      PILIH PEMILIK PANEL"
        echo "==================================="
        echo " 1. Panel Milik Manz"
        echo " 2. Panel Milik Dinz"
        echo " 0. Kembali"
        echo "==================================="
        read -p "Pilih Pemilik [1-2]: " owner_panel_opt

        case $owner_panel_opt in
            1)
                # LAYER 3: LIST PANEL MANZ
                clear
                echo "==================================="
                echo "      LIST PANEL MANZ"
                echo "==================================="
                echo " 1. Panel Manz Utama"
                echo " 0. Kembali"
                echo "==================================="
                read -p "Pilih Panel [1]: " pm_opt
                case $pm_opt in
                    1) install_tunnel "Panel Manz" "$panel_m" ;;
                    0) exit 0 ;;
                    *) echo "Salah!"; exit 1 ;;
                esac
                ;;
            2)
                # LAYER 3: LIST PANEL DINZ
                clear
                echo "==================================="
                echo "      LIST PANEL DINZ"
                echo "==================================="
                echo " 1. Panel Dinz Utama"
                echo " 0. Kembali"
                echo "==================================="
                read -p "Pilih Panel [1]: " pd_opt
                case $pd_opt in
                    1) install_tunnel "Panel Dinz" "$panel_d" ;;
                    0) exit 0 ;;
                    *) echo "Salah!"; exit 1 ;;
                esac
                ;;
            0) exit 0 ;;
            *) echo "Menu tidak valid."; exit 1 ;;
        esac
        ;;

    2)
        # ==========================================
        # LAYER 2: PILIH PEMILIK NODE
        # ==========================================
        clear
        echo "==================================="
        echo "      PILIH PEMILIK NODE"
        echo "==================================="
        echo " 1. Node Milik Manz"
        echo " 2. Node Milik Dinz"
        echo " 0. Kembali"
        echo "==================================="
        read -p "Pilih Pemilik [1-2]: " owner_node_opt

        case $owner_node_opt in
            1)
                # LAYER 3: LIST NODE MANZ
                clear
                echo "==================================="
                echo "      LIST NODE MANZ"
                echo "==================================="
                echo " 1. Node Manz 1"
                echo " 2. Node Manz 2"
                echo " 0. Kembali"
                echo "==================================="
                read -p "Pilih Node [1-2]: " nm_opt
                case $nm_opt in
                    1) install_tunnel "Node Manz 1" "$node_m_1" ;;
                    2) install_tunnel "Node Manz 2" "$node_m_2" ;;
                    0) exit 0 ;;
                    *) echo "Salah!"; exit 1 ;;
                esac
                ;;
            2)
                # LAYER 3: LIST NODE DINZ
                clear
                echo "==================================="
                echo "      LIST NODE DINZ"
                echo "==================================="
                echo " 1. Node Dinz 1"
                echo " 2. Node Dinz 2"
                echo " 0. Kembali"
                echo "==================================="
                read -p "Pilih Node [1-2]: " nd_opt
                case $nd_opt in
                    1) install_tunnel "Node Dinz 1" "$node_d_1" ;;
                    2) install_tunnel "Node Dinz 2" "$node_d_2" ;;
                    0) exit 0 ;;
                    *) echo "Salah!"; exit 1 ;;
                esac
                ;;
            0) exit 0 ;;
            *) echo "Menu tidak valid."; exit 1 ;;
        esac
        ;;

    0) exit 0 ;;
    *) echo "Menu tidak valid."; exit 1 ;;
esac
