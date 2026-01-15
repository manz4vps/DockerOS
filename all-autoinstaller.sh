#!/bin/bash  

# === KONFIGURASI WARNA ===
MERAH="\033[31m"
HIJAU="\033[32m"
KUNING="\033[33m"
BIRU="\033[36m"
UNGU="\033[35m"
CYAN="\033[1;36m"
PUTIH="\033[37m"
RESET="\033[0m"
TEBAL="\033[1m"

# Trap CTRL+C
trap 'echo -e "\n${MERAH}Exiting...${RESET}"; exit 0' SIGINT

# Banner ManzXD
banner() {
    clear
    echo -e "${CYAN}=============================================${RESET}"
    echo -e "${UNGU}   __  __                  __  __  ____  ${RESET}"
    echo -e "${UNGU}  |  \/  | __ _ _ __  ____ \ \/ / |  _ \ ${RESET}"
    echo -e "${UNGU}  | |\/| |/ _\` | '_ \|_  /  \  /  | | | |${RESET}"
    echo -e "${UNGU}  | |  | | (_| | | | |/ /   /  \  | |_| |${RESET}"
    echo -e "${UNGU}  |_|  |_|\__,_|_| |_/___| /_/\_\ |____/ ${RESET}"
    echo -e "${CYAN}=============================================${RESET}"
    echo -e "${PUTIH}      DOCKER OS INSTALLER | BY MANZXD    ${RESET}"
    echo -e "${CYAN}=============================================${RESET}"
}

# Cek curl
cek_curl() {
    if ! command -v curl &>/dev/null; then
        echo -ne "${KUNING}⚙️  Sedang menginstall curl...${RESET}"
        if [ -f /etc/debian_version ]; then
            apt-get update -qq && apt-get install -y curl -qq > /dev/null 2>&1
        elif [ -f /etc/redhat-release ]; then
            yum install -y curl > /dev/null 2>&1
        fi
        echo -e " ${HIJAU}[OK]${RESET}"
    fi
}

# Fungsi Jalankan
jalankan() {
    local url=$1
    cek_curl
    echo -e "\n${HIJAU}🚀 Menjalankan script...${RESET}"
    sleep 1
    bash <(curl -fsSL "$url")
    echo -e "\n${CYAN}---------------------------------------------${RESET}"
    read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali..."
}

# === SUB-MENU CONNECTION ===
menu_connection() {
    while true; do
        clear
        echo -e "${CYAN}=============================================${RESET}"
        echo -e "${KUNING}          🌐 MENU KONEKSI & TUNNEL          ${RESET}"
        echo -e "${CYAN}=============================================${RESET}"
        echo -e " ${TEBAL}1)${RESET}⚒️  Install Localtonet"
        echo -e " ${TEBAL}2)${RESET}🔨 Install Tailscale"
        echo -e " ${TEBAL}3)${RESET}🔨 Tailscale (IP Public)"
        echo -e " ${TEBAL}4)${RESET}⚒️  Install MineCube (IP Minecraft)"
        echo -e " ${TEBAL}5)${RESET}🛠️  Install Playit.gg"
        echo -e " ${TEBAL}6)${RESET}🖥️  Playit Run 24/7"
        echo -e "${CYAN}---------------------------------------------${RESET}"
        echo -e " ${TEBAL}0)${RESET} 🔙  Kembali ke Menu Utama"
        echo -e "${CYAN}=============================================${RESET}"
        echo -ne "${TEBAL}Pilih [0-4]: ${RESET}"
        read -r sub_opt
        case $sub_opt in
            1) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/install-localtonet.sh" ;;
            2) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/install-tailscale.sh" ;;
            3) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/tailscale-port.sh" ;;
            4) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/minekub-ip.sh" ;;
            5) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/playitInstaller.sh" ;;
            6) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/playit24%5C7" ;;
            0) return ;;
            *) echo -e "${MERAH}Pilihan salah.${RESET}"; sleep 1 ;;
        esac
    done
}

# === SUB-MENU CLOUDFLARE ===
menu_cloudflare() {
    while true; do
        clear
        echo -e "${CYAN}=============================================${RESET}"
        echo -e "${KUNING}           ☁️  MENU CLOUDFLARE              ${RESET}"
        echo -e "${CYAN}=============================================${RESET}"
        echo -e " ${TEBAL}1.${RESET} ☁️   Cloudflare Raw Script (Manual)"
        echo -e " ${TEBAL}2.${RESET} 🔒  Cloudflared Tunnel (Token)"
        echo -e "${CYAN}---------------------------------------------${RESET}"
        echo -e " ${TEBAL}0.${RESET} 🔙  Kembali ke Menu Utama"
        echo -e "${CYAN}=============================================${RESET}"
        echo -ne "${TEBAL}Pilih [0-2]: ${RESET}"
        read -r sub_opt
        case $sub_opt in
            1) jalankan "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/cloudflare.sh" ;;
            2) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/token-cloudflare.sh" ;;
            0) return ;;
            *) echo -e "${MERAH}Pilihan salah.${RESET}"; sleep 1 ;;
        esac
    done
}

# === MAIN MENU ===
while true; do
    banner
    echo -e " ${TEBAL}1)${RESET}🧩 Panel Pterodactyl"
    echo -e " ${TEBAL}2)${RESET}🪶  Wings Pterodactyl"
    echo -e " ${TEBAL}3)${RESET}🚀 SSH (connect)"
    echo -e " ${TEBAL}4)${RESET}🌐 Connection Tools (Playit/MineCube) ▶"
    echo -e " ${TEBAL}5)${RESET}🧱 Blueprint Framework"
    echo -e " ${TEBAL}6)${RESET}☁️  Install Cloudflare ▶"
    echo -e " ${TEBAL}7)${RESET}🎨 Pasang Tema (Theme)"
    echo -e " ${TEBAL}8)${RESET}🔌 Install Addon"
    echo -e " ${TEBAL}9)${RESET}🚀 Install SSHX (Remote)"
    
    echo -e "${CYAN}---------------------------------------------${RESET}"
    echo -e " ${TEBAL}0)${RESET} 🚪  KELUAR"
    echo -e "${CYAN}=============================================${RESET}"
    
    echo -ne "${TEBAL}Masukkan pilihan [0-8]: ${RESET}"
    read -r pilihan

    case $pilihan in
        1) jalankan "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/panel.sh" ;;
        2) jalankan "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/wings.sh" ;;
        3) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/ssh.sh" ;;
        4) menu_connection ;;  # Masuk ke Sub-Menu Connection
        5) jalankan "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/blueprint.sh" ;;
        6) menu_cloudflare ;;  # Masuk ke Sub-Menu Cloudflare
        7) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/theme.sh" ;;
        8) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/addon.sh" ;;
        9) jalankan "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/sshx.sh" ;;
        0) 
            echo -e "\n${HIJAU}Terimakasih Telah Menggunakan Scrip Ini!${RESET}"
            exit 0 
            ;;
        *) 
            echo -e "\n${MERAH}[!] Pilihan tidak valid, pilih 0-8.${RESET}"
            sleep 1
            ;;
    esac
done
