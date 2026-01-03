#!/bin/bash  

# Warna
MERAH="\033[31m"
HIJAU="\033[32m"
KUNING="\033[33m"
BIRU="\033[36m"
PUTIH="\033[37m"
RESET="\033[0m"
TEBAL="\033[1m"

# Banner
banner() {
    clear
    echo -e "${BIRU}${TEBAL}"
    echo "====================================="
    echo "        LAUNCHER SCRIPT OTOMATIS     "
    echo "          Dibuat oleh Manz4Ndaa      "
    echo "====================================="
    echo -e "${RESET}"
}

# Cek curl
cek_curl() {
    if ! command -v curl &>/dev/null; then
        echo -e "${MERAH}${TEBAL}Error: curl belum terpasang.${RESET}"
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y curl
        elif command -v yum &>/dev/null; then
            yum install -y curl
        elif command -v dnf &>/dev/null; then
            dnf install -y curl
        else
            echo -e "${MERAH}Gagal install curl.${RESET}"
            exit 1
        fi
    fi
}

# Jalankan script dari URL
jalankan_script() {
    local url=$1
    cek_curl
    bash <(curl -fsSL "$url")
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

# === PASANG TEMA ===
pasang_tema() {
    banner
    echo "1. Nebula Theme"
    echo "2. Euphoria Theme"
    echo "3. NookTheme"
    echo "4. Kembali"
    read -p "Pilih: " t
    case $t in
        1) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/change%20theme.sh" ;;
        2)
            cd /var/www/pterodactyl || return
            curl -fsSLO https://github.com/manz4vps/DockerOS/raw/refs/heads/main/euphoriatheme.blueprint
            blueprint -i euphoriatheme.blueprint
            ;;
        3) jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/NookTheme.sh" ;;
        
    esac
    read -p "Enter..."
}

# === Playit Run 24/7 ===#
install_playit() {
    cek_curl
    bash <(curl -fsSL "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/playit.sh")
    read -p "Tekan Enter..."
}

# === INSTALL ADDON PANEL (8 BLUEPRINT) ===
install_addon_panel() {
    banner
    echo -e "${TEBAL}=== INSTALL ADDON PANEL (8 ADDON) ===${RESET}"
    cd /var/www/pterodactyl || return

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
        curl -fsSLO "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/$addon"
        blueprint -i "$addon"
    done

    read -p "Tekan Enter..."
}

# === MENU UTAMA (FIX WARNA + CURL SAFE) ===
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
"${TEBAL}9.${RESET} 🧩 Install Addon" \
"${TEBAL}10.${RESET} 🚪 Keluar" \
"${TEBAL}================================${RESET}"
    echo -ne "${TEBAL}Masukkan pilihan [1-10]: ${RESET}"
}

# === LOOP UTAMA ===
while true; do
    tampilkan_menu
    read -r pilihan
    case $pilihan in
        1) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/panel.sh" ;;
        2) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/wings.sh" ;;
        3) jalankan_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/playitInstaller.sh" ;;
        4) install_playit ;;
        5) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/blueprint.sh" ;;
        6) jalankan_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/cloudflare.sh" ;;
        7) pasang_tema ;;
        8) install_cloudflared ;;
        9) install_addon_panel ;;
        10) exit 0 ;;
    esac
done
