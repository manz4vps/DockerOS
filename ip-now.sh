#!/bin/bash

# Warna biar enak dibaca
HIJAU='\033[0;32m'
MERAH='\033[0;31m'
KUNING='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

# Cek Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${MERAH}ERROR: Harap jalankan sebagai root! (sudo ./tunnel.sh)${RESET}"
  exit
fi

# Fungsi Install Tailscale (Disimpan di luar loop)
install_tailscale() {
    if ! command -v tailscale &> /dev/null; then
        echo -e "\n${KUNING}[*] Menginstall Tailscale...${RESET}"
        curl -fsSL https://tailscale.com/install.sh | sh
        echo -e "${HIJAU}[+] Tailscale terinstall!${RESET}"
        sudo tailscale up
    else
        echo -e "${HIJAU}[✓] Tailscale sudah siap.${RESET}"
    fi
}

# --- LOOP MENU UTAMA ---
while true; do
    clear
    echo -e "${CYAN}=============================================${RESET}"
    echo -e "${KUNING}   MINECRAFT TUNNEL MANAGER V3.0 (Auto-Loop)   ${RESET}"
    echo -e "${CYAN}=============================================${RESET}"
    echo ""
    echo "Pilih Menu:"
    echo -e "[1] ${HIJAU}Install Baru / Setup Awal${RESET}"
    echo -e "[2] ${KUNING}Tambah Port Baru${RESET} (Server ke-2, dst)"
    echo -e "[3] ${CYAN}Cek Status & IP${RESET}"
    echo -e "[0] Keluar"
    echo ""
    read -p "Pilih nomor (0-3): " MENU

    case $MENU in
        1)
            # === MENU 1: SETUP AWAL ===
            echo -e "\n--- SETUP AWAL ---"
            echo "Kamu di VPS mana sekarang?"
            echo -e "[1] ${HIJAU}VPS PRIVATE${RESET} (Tempat Game Server)"
            echo -e "[2] ${HIJAU}VPS PUBLIC${RESET}  (Jembatan / IP Public)"
            read -p "Pilih (1/2): " ROLE

            if [ "$ROLE" == "1" ]; then
                install_tailscale
                IP_TS=$(tailscale ip -4)
                echo -e "\n${HIJAU}=============================================${RESET}"
                echo -e "SETUP VPS PRIVATE SELESAI!"
                echo -e "Simpan IP ini untuk setting di VPS Public:"
                echo -e "${KUNING}IP Tailscale: ${IP_TS}${RESET}"
                echo -e "${HIJAU}=============================================${RESET}"
            
            elif [ "$ROLE" == "2" ]; then
                install_tailscale
                echo -e "\n${KUNING}[*] Menginstall Rinetd (Jembatan)...${RESET}"
                apt update && apt install rinetd -y
                
                read -p "Masukkan IP Tailscale VPS Private: " TARGET_IP
                read -p "Masukkan Port Game Utama (Default 25565): " PORT_GAME
                PORT_GAME=${PORT_GAME:-25565}

                cp /etc/rinetd.conf /etc/rinetd.conf.bak 2>/dev/null
                echo "# Config Auto-Tunnel Minecraft" > /etc/rinetd.conf
                echo "0.0.0.0 $PORT_GAME $TARGET_IP $PORT_GAME" >> /etc/rinetd.conf
                
                systemctl restart rinetd
                ufw allow $PORT_GAME/tcp > /dev/null 2>&1
                
                IP_PUB=$(curl -s ifconfig.me)
                echo -e "\n${HIJAU}[SUCCESS] Setup Selesai!${RESET}"
                echo -e "IP Public: ${KUNING}${IP_PUB}:${PORT_GAME}${RESET}"
            fi
            
            echo ""
            read -p "Tekan ENTER untuk kembali ke menu..."
            ;;

        2)
            # === MENU 2: TAMBAH PORT BARU ===
            echo -e "\n${KUNING}--- TAMBAH SERVER BARU (ADD PORT) ---${RESET}"
            
            # Cek apakah rinetd ada (Tanda ini VPS Public)
            if ! command -v rinetd &> /dev/null; then
                echo -e "${MERAH}Error: Rinetd tidak ditemukan. Ini VPS Public bukan?${RESET}"
                echo -e "Silakan pilih menu [1] dulu untuk install awal."
                read -p "Tekan ENTER untuk kembali..."
                continue
            fi

            echo -e "Masukkan Data Server Baru:"
            read -p "IP Tailscale VPS Private (Target): " TARGET_IP
            read -p "Port Baru yang mau dibuka (misal 25566): " NEW_PORT
            
            if [[ -z "$NEW_PORT" ]]; then
                echo -e "${MERAH}Port tidak boleh kosong!${RESET}"
            else
                echo "0.0.0.0 $NEW_PORT $TARGET_IP $NEW_PORT" >> /etc/rinetd.conf
                echo -e "${KUNING}[*] Restarting services...${RESET}"
                systemctl restart rinetd
                ufw allow $NEW_PORT/tcp > /dev/null 2>&1
                
                IP_PUB=$(curl -s ifconfig.me)
                echo -e "\n${HIJAU}[SUCCESS] Server Baru Ditambahkan!${RESET}"
                echo -e "Player bisa join ke: ${KUNING}${IP_PUB}:${NEW_PORT}${RESET}"
            fi
            
            echo ""
            read -p "Tekan ENTER untuk kembali ke menu..."
            ;;

        3)
            # === MENU 3: CEK STATUS ===
            echo -e "\n${CYAN}--- STATUS SAAT INI ---${RESET}"
            if command -v tailscale &> /dev/null; then
                echo -e "Status Tailscale: $(tailscale status | head -n 1)"
                echo -e "IP Tailscale Saya: ${KUNING}$(tailscale ip -4)${RESET}"
            else
                echo -e "Tailscale: ${MERAH}Belum Terinstall${RESET}"
            fi

            if [ -f /etc/rinetd.conf ]; then
                echo -e "\n${CYAN}List Port yang dibuka (Forwarding):${RESET}"
                # Menampilkan isi config tanpa komentar (#) dan baris kosong
                grep -v "^#" /etc/rinetd.conf | grep -v "^$" 
            fi
            
            echo ""
            echo -e "${KUNING}NOTE: Tekan ENTER jika sudah selesai melihat.${RESET}"
            read -p "" # Ini yang bikin dia pause
            ;;
        
        0)
            echo -e "${HIJAU}Keluar... Bye bro!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${MERAH}Pilihan tidak valid!${RESET}"
            sleep 1
            ;;
    esac
done
