#!/bin/bash

# Cloudflared Installer (3-Layer Menu)
# Created by ManzXD

# ==========================================
# 1. KONFIGURASI TOKEN
# ==========================================

# --- PANEL ---
panel_m="TOKEN_PANEL_MANZ_DISINI"
panel_d="TOKEN_PANEL_DINZ_DISINI"

# --- NODE MANZ ---
node1_m="TOKEN_MANZ_NODE_1_DISINI"
node2_m="TOKEN_MANZ_NODE_2_DISINI"

# --- NODE DINZ ---
node1_d="TOKEN_DINZ_NODE_1_DISINI"
node2_d="TOKEN_DINZ_NODE_2_DISINI"


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
        # LAYER 2: PANEL
        clear
        echo "==================================="
        echo "      PILIH PEMILIK PANEL"
        echo "==================================="
        echo " 1. Panel Manz"
        echo " 2. Panel Dinz"
        echo " 0. Kembali"
        echo "==================================="
        read -p "Pilih Panel [1-2]: " panel_opt

        case $panel_opt in
            1) install_tunnel "Panel Manz" "$panel_m" ;;
            2) install_tunnel "Panel Dinz" "$panel_d" ;;
            0) exit 0 ;;
            *) echo "Pilihan salah!"; exit 1 ;;
        esac
        ;;

    2)
        # LAYER 2: NODE (OWNER)
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
                read -p "Pilih Node Manz [1-2]: " nm_opt

                case $nm_opt in
                    1) install_tunnel "Node Manz 1" "$node1_m" ;;
                    2) install_tunnel "Node Manz 2" "$node2_m" ;;
                    0) exit 0 ;;
                    *) echo "Pilihan salah!"; exit 1 ;;
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
                read -p "Pilih Node Dinz [1-2]: " nd_opt

                case $nd_opt in
                    1) install_tunnel "Node Dinz 1" "$node1_d" ;;
                    2) install_tunnel "Node Dinz 2" "$node2_d" ;;
                    0) exit 0 ;;
                    *) echo "Pilihan salah!"; exit 1 ;;
                esac
                ;;

            0) exit 0 ;;
            *) echo "Pilihan salah!"; exit 1 ;;
        esac
        ;;

    0) exit 0 ;;
    *) echo "Menu tidak valid."; exit 1 ;;
esac
