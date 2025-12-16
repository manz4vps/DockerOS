#!/bin/bash

# ===== WARNA (AMAN CURL PIPE) =====
MERAH="\033[31m"
HIJAU="\033[32m"
KUNING="\033[33m"
BIRU="\033[36m"
PUTIH="\033[37m"
RESET="\033[0m"
TEBAL="\033[1m"

# ===== BANNER =====
banner() {
    clear
    echo -e "${BIRU}${TEBAL}"
    echo "====================================="
    echo "        LAUNCHER SCRIPT OTOMATIS     "
    echo "          Dibuat oleh Manz4Ndaa      "
    echo "====================================="
    echo -e "${RESET}"
}

# ===== CEK CURL =====
cek_curl() {
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${KUNING}Menginstall curl...${RESET}"
        apt-get update && apt-get install -y curl
    fi
}

# ===== JALANKAN SCRIPT URL =====
jalankan_script() {
    local url="$1"
    cek_curl
    bash <(curl -fsSL "$url")
    read -p "Tekan Enter untuk kembali ke menu..."
}

# ===== INSTALL ADDON PANEL (8) =====
install_addon_panel() {
    banner
    echo -e "${TEBAL}INSTALL ADDON PANEL (8 BLUEPRINT)${RESET}"

    cd /var/www/pterodactyl || {
        echo -e "${MERAH}Folder Pterodactyl tidak ditemukan!${RESET}"
        read -p "Enter..."
        return
    }

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

    for addon in "${addons[@]}"; do
        echo -e "${KUNING}→ $addon${RESET}"
        wget -q "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/$addon"
        blueprint -i "$addon"
    done

    echo -e "${HIJAU}Semua addon selesai.${RESET}"
    read -p "Tekan Enter..."
}

# ===== CLOUDFLARED =====
install_cloudflared() {
    banner
    echo "1. Tunnel Manz"
    echo "2. Tunnel Dinz"
    echo "3. Kembali"
    read -p "Pilih: " pilih

    case $pilih in
        1) cloudflared service install TOKEN_MANZ ;;
        2) cloudflared service install TOKEN_DINZ ;;
    esac

    read -p "Enter..."
}

tampilkan_menu() {
    banner
    printf "%b\n" \
"${TEBAL}========== MENU UTAMA ==========${RESET}" \
"${TEBAL}1.${RESET} 🧩 Panel" \
"${TEBAL}2.${RESET} 🪶 Wings" \
"${TEBAL}3.${RESET} 🛠️ Install Playit" \
"${TEBAL}4.${RESET} 🖥️ Playit Run 24/7" \
"${TEBAL}5.${RESET} 🧱 Blueprint" \
"${TEBAL}6.${RESET} ☁️  Cloudflare (raw script)" \
"${TEBAL}7.${RESET} 🎨 Pasang Tema" \
"${TEBAL}8.${RESET} 🔒 Cloudflared Tunnel" \
"${TEBAL}9.${RESET} 🧩 Install Addon (8)" \
"${TEBAL}10.${RESET} 🚪 Keluar" \
"${TEBAL}==============================${RESET}"
    echo -ne "${TEBAL}Masukkan pilihan [1-10]: ${RESET}"
}

# ===== LOOP =====
while true; do
    tampilkan_menu
    read pilih
    case $pilih in
        1) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/main/panel.sh" ;;
        2) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/main/wings.sh" ;;
        3) jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/main/playitInstaller.sh" ;;
        4) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/main/blueprint.sh" ;;
        5) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/main/cloudflare.sh" ;;
        6) install_cloudflared ;;
        7) install_addon_panel ;;
        8) exit 0 ;;
        *) echo "Pilihan salah"; sleep 1 ;;
    esac
done
