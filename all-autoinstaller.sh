#!/bin/bash  

#Warna

MERAH="\e[31m"
HIJAU="\e[32m"
KUNING="\e[33m"
BIRU="\e[36m"
PUTIH="\e[37m"
RESET="\e[0m"
TEBAL="\e[1m"

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
        echo -e "${KUNING}Menginstall curl...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get update && sudo apt-get install -y curl
        elif command -v yum &>/dev/null; then
            sudo yum install -y curl
        elif command -v dnf &>/dev/null; then
            sudo dnf install -y curl
        else
            echo -e "${MERAH}Gagal menginstall curl otomatis.${RESET}"
            exit 1
        fi
        echo -e "${HIJAU}curl berhasil dipasang!${RESET}"
    fi
}

# Jalankan script dari URL
jalankan_script() {
    local url=$1
    local nama_script=$(basename "$url" .sh)
    nama_script=$(echo "$nama_script" | sed 's/.*/\u&/')

    echo -e "${KUNING}${TEBAL}Menjalankan: ${BIRU}${nama_script}${RESET}"
    cek_curl

    local temp_script=$(mktemp)
    echo -e "${KUNING}Mengunduh script...${RESET}"

    if curl -fsSL "$url" -o "$temp_script"; then
        echo -e "${HIJAU}✓ Unduhan berhasil${RESET}"
        chmod +x "$temp_script"
        bash "$temp_script"
        local kode=$?
        rm -f "$temp_script"
        if [ $kode -eq 0 ]; then
            echo -e "${HIJAU}✅ Script berhasil dijalankan${RESET}"
        else
            echo -e "${MERAH}✗ Script gagal dijalankan (kode $kode)${RESET}"
        fi
    else
        echo -e "${MERAH}✗ Gagal mengunduh script${RESET}"
    fi
    echo
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

# === INSTALL ADDON PANEL (8 BLUEPRINT) ===
install_addon_panel() {
    banner
    echo -e "${TEBAL}=== INSTALL ADDON PANEL (8 ADDON) ===${RESET}"

    cek_curl
    cd /var/www/pterodactyl || { echo -e "${MERAH}Folder tidak ditemukan!${RESET}"; return; }

    addons=(
        "mcplugins.blueprint"
        "minecraftplayermanager.blueprint"
        "loader.blueprint"
        "serverbackgrounds.blueprint"
        "simplefavicons.blueprint"
        "startupchanger.blueprint"
        "subdomains.blueprint"
        "versionchanger.blueprint"
    )

    for addon in "${addons[@]}"; do
        echo -e "${KUNING}Mengunduh $addon...${RESET}"
        wget -q "https://github.com/manz4vps/DockerOS/raw/refs/heads/main/$addon"

        if [ -f "$addon" ]; then
            echo -e "${BIRU}Menginstall $addon...${RESET}"
            blueprint -i "$addon" && echo -e "${HIJAU}✓ $addon berhasil diinstal${RESET}"
        else
            echo -e "${MERAH}✗ Gagal mengunduh $addon${RESET}"
        fi
        echo
    done

    echo -e "${HIJAU}${TEBAL}Semua addon berhasil diproses.${RESET}"
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

# === CLOUDFARED INSTALL ===
install_cloudflared() {
    banner
    echo -e "${TEBAL}=== PILIH TUNNEL CLOUDFLARED ===${RESET}"
    echo -e "1. Tunnel Manz"
    echo -e "2. Tunnel Dinz"
    echo -e "3. Kembali"
    echo -ne "${TEBAL}Pilih tunnel [1-3]: ${RESET}"
    read -r pilih_tunnel

    case $pilih_tunnel in
        1) sudo cloudflared service install TOKEN_MANZ ;;
        2) sudo cloudflared service install TOKEN_DINZ ;;
        3) ;;
        *) echo -e "${MERAH}Pilihan tidak valid!${RESET}" ;;
    esac
    read -p "Tekan Enter untuk kembali ke menu utama..."
}

# === MENU UTAMA ===
tampilkan_menu() {
banner
menu_content=$(cat <<EOF
${TEBAL}========== MENU UTAMA ===========${RESET}
${TEBAL}1.${RESET} 🧩 Panel
${TEBAL}2.${RESET} 🪶 Wings
${TEBAL}3.${RESET} 🛠️ Install Playit
${TEBAL}4.${RESET} 🖥️ Playit Run 24/7
${TEBAL}5.${RESET} 🧱 Blueprint
${TEBAL}6.${RESET} ☁️  Cloudflare (raw script)
${TEBAL}7.${RESET} 🎨 Pasang Tema
${TEBAL}8.${RESET} 🔒 Cloudflared Tunnel
${TEBAL}9.${RESET} 🧩 Install Addon
${TEBAL}10.${RESET} 🚪 Keluar
${TEBAL}=================================${RESET}
EOF
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
        10) echo -e "${HIJAU}👋 Keluar...${RESET}"; exit 0 ;;
        *) echo -e "${MERAH}Pilihan tidak valid!${RESET}"; read -p "Tekan Enter..." ;;
    esac
done
