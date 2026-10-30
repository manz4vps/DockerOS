#!/bin/bash

shopt -s nullglob

# =========================================================
# KONFIGURASI
# =========================================================

UBUNTU_URL="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/ubuntu-desktop.sh"

# Warna terminal
RESET='\033[0m'
BOLD='\033[1m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
BLUE='\033[1;34m'

# =========================================================
# HEADER PANEL
# =========================================================

header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║          MANZ4VPS VIRTUAL SYSTEM              ║"
    echo "║             CONTROL PANEL                    ║"
    echo "║                                              ║"
    echo "╠══════════════════════════════════════════════╣"
    echo "║          WINDOWS & UBUNTU MANAGER             ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

pause() {
    echo
    read -rp "Tekan ENTER untuk kembali ke menu..."
}

# =========================================================
# MENU UTAMA
# =========================================================

while true; do

    header

    echo -e "${WHITE}${BOLD}  MENU UTAMA${RESET}"
    echo
    echo -e "  ${GREEN}[1]${RESET} Jalankan Windows baru"
    echo -e "  ${GREEN}[2]${RESET} Jalankan Ubuntu Desktop (VNC)"
    echo -e "  ${GREEN}[3]${RESET} Lihat Windows aktif"
    echo -e "  ${GREEN}[4]${RESET} Masuk ke Windows"
    echo -e "  ${RED}[5]${RESET} Hapus Windows"
    echo
    echo -e "  ${YELLOW}[0]${RESET} Keluar"
    echo
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

    read -rp "  Pilih menu [0-5]: " SISTEM

    # =====================================================
    # MENU 0: KELUAR
    # =====================================================

    if [[ "$SISTEM" == "0" ]]; then
        clear
        echo -e "${GREEN}${BOLD}"
        echo "╔══════════════════════════════════════════════╗"
        echo "║                                              ║"
        echo "║       TERIMA KASIH TELAH MENGGUNAKAN         ║"
        echo "║              MANZ4VPS PANEL                  ║"
        echo "║                                              ║"
        echo "╚══════════════════════════════════════════════╝"
        echo -e "${RESET}"
        exit 0
    fi

    # =====================================================
    # MENU 1: WINDOWS
    # =====================================================

    if [[ "$SISTEM" == "1" ]]; then

        header

        echo -e "${CYAN}${BOLD}  WINDOWS INSTALLATION${RESET}"
        echo
        echo "  Value  | Version"
        echo "  ---------------------------------------"
        echo "  11     | Windows 11 Pro"
        echo "  11l    | Windows 11 LTSC"
        echo "  11e    | Windows 11 Enterprise"
        echo "  10     | Windows 10 Pro"
        echo "  10l    | Windows 10 LTSC"
        echo "  10e    | Windows 10 Enterprise"
        echo "  8e     | Windows 8.1 Enterprise"
        echo "  7e     | Windows 7 Enterprise"
        echo "  ve     | Windows Vista Enterprise"
        echo "  xp     | Windows XP Professional"
        echo "  2025   | Windows Server 2025"
        echo "  2022   | Windows Server 2022"
        echo "  2019   | Windows Server 2019"
        echo "  2016   | Windows Server 2016"
        echo "  2012   | Windows Server 2012"
        echo "  2008   | Windows Server 2008"
        echo "  2003   | Windows Server 2003"
        echo

        read -rp "Masukkan versi (default: 10l): " VERSION
        VERSION=${VERSION:-10l}

        read -rp "Username RDP (default: ManzXD): " USERNAME
        USERNAME=${USERNAME:-ManzXD}

        read -rsp "Password RDP (default: ManzXD): " PASSWORD
        PASSWORD=${PASSWORD:-ManzXD}
        echo

        read -rp "RAM (default: 4G): " RAM
        RAM=${RAM:-4G}

        read -rp "Jumlah CPU (default: 2): " CPU
        CPU=${CPU:-2}

        read -rp "Disk utama (default: 20G): " DISK1
        DISK1=${DISK1:-20G}

        read -rp "Disk kedua (default: 20G): " DISK2
        DISK2=${DISK2:-20G}

        # Download VB-CABLE

        echo
        echo -e "${YELLOW}Mempersiapkan shared folder...${RESET}"

        mkdir -p ./shared_data

        if [[ ! -f "./shared_data/VBCABLE_Driver_Pack45.zip" ]]; then

            if ! curl -fL \
                -o ./shared_data/VBCABLE_Driver_Pack45.zip \
                https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack45.zip; then

                echo -e "${RED}Download VB-CABLE gagal.${RESET}"
                pause
                continue
            fi

            echo -e "${GREEN}VB-CABLE berhasil didownload.${RESET}"

        else
            echo "VB-CABLE sudah tersedia, melewati download."
        fi

        YAML_FILE="windows${VERSION}.yml"

        cat > "$YAML_FILE" <<EOL
version: "3.3"
services:
  windows:
    image: manz4vps/windows
    container_name: windows
    environment:
      VERSION: "$VERSION"
      USERNAME: "$USERNAME"
      PASSWORD: "$PASSWORD"
      RAM_SIZE: "$RAM"
      CPU_CORES: "$CPU"
      DISK_SIZE: "$DISK1"
      DISK2_SIZE: "$DISK2"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    volumes:
      - ./shared_data:/storage
    stop_grace_period: 2m
EOL

        echo
        echo -e "${GREEN}File $YAML_FILE berhasil dibuat.${RESET}"
        echo -e "${YELLOW}Menjalankan Windows...${RESET}"

        sudo docker-compose -f "$YAML_FILE" up -d

        echo
        echo -e "${GREEN}Windows berhasil dijalankan.${RESET}"
        echo "Gunakan menu 4 untuk masuk ke Windows."

        pause
        continue
    fi

    # =====================================================
    # MENU 2: UBUNTU DESKTOP
    # =====================================================

    if [[ "$SISTEM" == "2" ]]; then

        header

        echo -e "${CYAN}${BOLD}  UBUNTU DESKTOP INSTALLER${RESET}"
        echo
        echo -e "${GREEN}Menghubungkan ke Ubuntu Desktop installer...${RESET}"
        echo

        if ! command -v curl >/dev/null 2>&1; then
            echo -e "${YELLOW}Curl belum tersedia. Menginstall curl...${RESET}"

            sudo apt-get update &&
            sudo apt-get install -y curl

            if ! command -v curl >/dev/null 2>&1; then
                echo -e "${RED}Gagal memasang curl.${RESET}"
                pause
                continue
            fi
        fi

        # Menjalankan installer Ubuntu dari GitHub RAW
        bash <(curl -fsSL "$UBUNTU_URL")

        echo
        echo -e "${GREEN}Proses Ubuntu Desktop selesai.${RESET}"

        pause
        continue
    fi

    # =====================================================
    # MENU 3: WINDOWS AKTIF
    # =====================================================

    if [[ "$SISTEM" == "3" ]]; then

        header

        echo -e "${CYAN}${BOLD}  WINDOWS CONTAINER STATUS${RESET}"
        echo

        sudo docker ps \
            --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        echo
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

        pause
        continue
    fi

    # =====================================================
    # MENU 4: MASUK WINDOWS
    # =====================================================

    if [[ "$SISTEM" == "4" ]]; then

        header

        FILES=(windows*.yml)

        if [[ ${#FILES[@]} -eq 0 ]]; then
            echo -e "${RED}Tidak ada file Windows ditemukan.${RESET}"
            pause
            continue
        fi

        echo -e "${CYAN}${BOLD}  PILIH WINDOWS${RESET}"
        echo

        i=1

        for f in "${FILES[@]}"; do
            echo "  [$i] $f"
            ((i++))
        done

        echo
        echo "  [0] Kembali"

        echo
        read -rp "Pilih nomor: " pilih

        if [[ "$pilih" == "0" ]]; then
            continue
        fi

        if ! [[ "$pilih" =~ ^[0-9]+$ ]] ||
           (( pilih < 1 || pilih > ${#FILES[@]} )); then

            echo -e "${RED}Pilihan tidak valid.${RESET}"
            pause
            continue
        fi

        FILE="${FILES[$((pilih-1))]}"

        echo
        echo -e "${YELLOW}Menjalankan $FILE...${RESET}"

        sudo docker-compose -f "$FILE" up -d

        sudo docker attach windows

        pause
        continue
    fi

    # =====================================================
    # MENU 5: HAPUS WINDOWS
    # =====================================================

    if [[ "$SISTEM" == "5" ]]; then

        header

        FILES=(windows*.yml)

        if [[ ${#FILES[@]} -eq 0 ]]; then
            echo -e "${RED}Tidak ada file Windows ditemukan.${RESET}"
            pause
            continue
        fi

        echo -e "${RED}${BOLD}  HAPUS WINDOWS${RESET}"
        echo

        i=1

        for f in "${FILES[@]}"; do
            echo "  [$i] $f"
            ((i++))
        done

        echo
        echo "  [0] Kembali"

        echo
        read -rp "Pilih nomor: " pilih

        if [[ "$pilih" == "0" ]]; then
            continue
        fi

        if ! [[ "$pilih" =~ ^[0-9]+$ ]] ||
           (( pilih < 1 || pilih > ${#FILES[@]} )); then

            echo -e "${RED}Pilihan tidak valid.${RESET}"
            pause
            continue
        fi

        FILE="${FILES[$((pilih-1))]}"

        echo
        echo -e "${YELLOW}Menghapus container dan volume...${RESET}"

        sudo docker-compose -f "$FILE" down -v

        echo
        echo -e "${YELLOW}Menghapus image Windows...${RESET}"

        sudo docker rmi manz4vps/windows -f 2>/dev/null

        echo
        echo -e "${YELLOW}Membersihkan resource Docker yang tidak digunakan...${RESET}"

        sudo docker system prune -a -f --volumes

        rm -f "$FILE"

        echo
        echo -e "${GREEN}${BOLD}Windows berhasil dihapus.${RESET}"

        pause
        continue
    fi

    # =====================================================
    # PILIHAN TIDAK VALID
    # =====================================================

    echo
    echo -e "${RED}Pilihan tidak valid! Silakan pilih 0-5.${RESET}"
    sleep 1

done
