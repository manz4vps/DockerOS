#!/bin/bash
set -e

# AUTO ROOT
if [ "$EUID" -ne 0 ]; then
    exec sudo -H bash "$(readlink -f "$0")" "$@"
fi

# WARNA
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
C='\033[0;36m'
M='\033[0;35m'
W='\033[1;37m'
N='\033[0m'

DIR="/root/ubuntu-vm"
FILE="$DIR/docker-compose.yml"
ENV="$DIR/.config"

RAM="4G"
CPU="2"
DISK="30G"
PORT="8006"

UBUNTU_VERSION="24.04 LTS"
BOOT_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.5.1-desktop-amd64.iso"

mkdir -p "$DIR"

load_config() {
    if [ -f "$ENV" ]; then
        source "$ENV"
    fi
}

save_config() {
    cat > "$ENV" <<EOF
RAM='$RAM'
CPU='$CPU'
DISK='$DISK'
PORT='$PORT'
UBUNTU_VERSION='$UBUNTU_VERSION'
BOOT_URL='$BOOT_URL'
EOF
}

header() {
    clear
    echo -e "${M}"
    echo "╔══════════════════════════════════════╗"
    echo "║       UBUNTU DESKTOP MANAGER         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${N}"
}

# PILIH VERSI UBUNTU
select_version() {
    while true; do
        header

        echo -e "${W}PILIH VERSI UBUNTU${N}"
        echo
        echo -e "${G}[1]${N} Ubuntu 20.04 LTS"
        echo -e "${G}[2]${N} Ubuntu 22.04 LTS"
        echo -e "${G}[3]${N} Ubuntu 24.04 LTS"
        echo -e "${G}[4]${N} Ubuntu 26.04 LTS"
        echo
        echo -e "${R}[0]${N} Kembali"
        echo

        read -p "Pilih versi: " pilih

        case "$pilih" in
            1)
                UBUNTU_VERSION="20.04 LTS"
                BOOT_URL="https://releases.ubuntu.com/20.04/ubuntu-20.04.6-desktop-amd64.iso"
                return 0
                ;;
            2)
                UBUNTU_VERSION="22.04 LTS"
                BOOT_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.5-desktop-amd64.iso"
                return 0
                ;;
            3)
                UBUNTU_VERSION="24.04 LTS"
                BOOT_URL="https://releases.ubuntu.com/24.04/ubuntu-24.04.5.1-desktop-amd64.iso"
                return 0
                ;;
            4)
                UBUNTU_VERSION="26.04 LTS"
                BOOT_URL="https://releases.ubuntu.com/26.04/ubuntu-26.04.1-desktop-amd64.iso"
                return 0
                ;;
            0)
                return 1
                ;;
            *)
                echo -e "${R}Pilihan tidak tersedia!${N}"
                sleep 1
                ;;
        esac
    done
}

# CREATE COMPOSE
create_compose() {
    mkdir -p "$DIR/storage"

    cat > "$FILE" <<EOF
services:
  ubuntu:
    image: qemux/qemu:latest
    container_name: ubuntu-desktop
    environment:
      BOOT: "$BOOT_URL"
      RAM_SIZE: "$RAM"
      CPU_CORES: "$CPU"
      DISK_SIZE: "$DISK"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "$PORT:8006"
    volumes:
      - ./storage:/storage
    restart: unless-stopped
    stop_grace_period: 2m
EOF
}

# MONITOR LOGS
monitor_logs() {
    echo
    echo -e "${Y}Memantau log Ubuntu Desktop...${N}"
    echo -e "${C}Tekan Ctrl+C untuk kembali ke menu.${N}"
    echo

    docker compose -f "$FILE" logs -f --no-color || true
}

# START DESKTOP
start_desktop() {
    echo
    echo -e "${Y}Menghentikan container lama...${N}"

    if [ -f "$FILE" ]; then
        docker compose -f "$FILE" down || true
    fi

    echo -e "${Y}Menghapus data Ubuntu lama...${N}"

    mkdir -p "$DIR/storage"

    find "$DIR/storage" -mindepth 1 -maxdepth 1 \
        -exec rm -rf -- {} +

    create_compose
    save_config

    echo
    echo -e "${Y}Menjalankan Ubuntu $UBUNTU_VERSION...${N}"
    echo -e "${C}ISO akan diunduh oleh Docker/QEMU.${N}"

    docker compose -f "$FILE" up -d

    echo
    echo -e "${G}[✓] Ubuntu Desktop berhasil dijalankan!${N}"
    echo -e "${C}Versi: Ubuntu $UBUNTU_VERSION${N}"
    echo -e "${C}Akses: http://localhost:$PORT${N}"

    monitor_logs
}

# EDIT SPECS
edit_specs() {
    while true; do
        header

        echo -e "${W}EDIT SPESIFIKASI${N}"
        echo
        echo -e "${G}[1]${N} RAM  : $RAM"
        echo -e "${G}[2]${N} CPU  : $CPU Core"
        echo -e "${G}[3]${N} DISK : $DISK"
        echo -e "${G}[4]${N} PORT : $PORT"
        echo -e "${R}[0]${N} Selesai Edit"
        echo -e "${R}[B]${N} Batalkan Konfigurasi"

        echo
        read -p "Pilih nomor: " pilih

        case "${pilih,,}" in
            1) read -p "RAM [$RAM]: " v; RAM=${v:-$RAM} ;;
            2) read -p "CPU [$CPU]: " v; CPU=${v:-$CPU} ;;
            3) read -p "DISK [$DISK]: " v; DISK=${v:-$DISK} ;;
            4) read -p "PORT [$PORT]: " v; PORT=${v:-$PORT} ;;
            0) return 0 ;;
            b) return 1 ;;
            *) echo -e "${R}Pilihan salah!${N}"; sleep 1 ;;
        esac
    done
}

# CREATE MENU
create_menu() {
    local OLD_RAM="$RAM"
    local OLD_CPU="$CPU"
    local OLD_DISK="$DISK"
    local OLD_PORT="$PORT"
    local OLD_VERSION="$UBUNTU_VERSION"
    local OLD_URL="$BOOT_URL"

    if ! select_version; then
        return
    fi

    header

    echo -e "${W}KONFIGURASI UBUNTU DESKTOP${N}"
    echo
    echo -e "${G}Versi: Ubuntu $UBUNTU_VERSION${N}"
    echo

    read -p "RAM [$RAM]: " v
    RAM=${v:-$RAM}

    read -p "CPU [$CPU]: " v
    CPU=${v:-$CPU}

    read -p "DISK [$DISK]: " v
    DISK=${v:-$DISK}

    read -p "PORT [$PORT]: " v
    PORT=${v:-$PORT}

    while true; do
        header

        echo -e "${W}KONFIRMASI KONFIGURASI${N}"
        echo
        echo "UBUNTU : $UBUNTU_VERSION"
        echo "RAM    : $RAM"
        echo "CPU    : $CPU Core"
        echo "DISK   : $DISK"
        echo "PORT   : $PORT"
        echo

        read -p "Lanjutkan? [Y/N]: " jawab

        case "${jawab,,}" in
            y)
                header

                echo -e "${R}PERINGATAN!${N}"
                echo
                echo "Instalasi Ubuntu sebelumnya akan dihapus."
                echo "Semua data di storage VM akan hilang."
                echo
                echo "Versi baru: Ubuntu $UBUNTU_VERSION"
                echo

                read -p "Yakin lanjut? [Y/N]: " hapus

                case "${hapus,,}" in
                    y)
                        start_desktop
                        break
                        ;;
                    *)
                        echo -e "${Y}Penggantian dibatalkan.${N}"
                        RAM="$OLD_RAM"
                        CPU="$OLD_CPU"
                        DISK="$OLD_DISK"
                        PORT="$OLD_PORT"
                        UBUNTU_VERSION="$OLD_VERSION"
                        BOOT_URL="$OLD_URL"
                        sleep 2
                        return
                        ;;
                esac
                ;;
            n)
                if ! edit_specs; then
                    RAM="$OLD_RAM"
                    CPU="$OLD_CPU"
                    DISK="$OLD_DISK"
                    PORT="$OLD_PORT"
                    UBUNTU_VERSION="$OLD_VERSION"
                    BOOT_URL="$OLD_URL"

                    echo -e "${Y}Konfigurasi dibatalkan.${N}"
                    sleep 1
                    return
                fi
                ;;
            *)
                echo -e "${R}Masukkan Y atau N${N}"
                sleep 1
                ;;
        esac
    done

    read -p "Tekan Enter..."
}

# RESTART DESKTOP
restart_desktop() {
    header

    echo -e "${Y}Restart Ubuntu Desktop...${N}"

    if [ ! -f "$FILE" ]; then
        echo -e "${R}Konfigurasi belum tersedia!${N}"
        read -p "Tekan Enter..."
        return
    fi

    create_compose
    save_config

    docker compose -f "$FILE" up -d --force-recreate

    echo -e "${G}[✓] Restart berhasil!${N}"
    echo -e "${C}Akses: http://localhost:$PORT${N}"

    monitor_logs

    read -p "Tekan Enter..."
}

# EDIT MENU
edit_menu() {
    local OLD_RAM="$RAM"
    local OLD_CPU="$CPU"
    local OLD_DISK="$DISK"
    local OLD_PORT="$PORT"

    if ! edit_specs; then
        RAM="$OLD_RAM"
        CPU="$OLD_CPU"
        DISK="$OLD_DISK"
        PORT="$OLD_PORT"
        return
    fi

    save_config

    header
    echo -e "${G}Konfigurasi berhasil disimpan!${N}"
    echo
    echo "RAM  : $RAM"
    echo "CPU  : $CPU Core"
    echo "DISK : $DISK"
    echo "PORT : $PORT"
    echo

    read -p "Restart sekarang? [Y/N]: " jawab

    case "${jawab,,}" in
        y) restart_desktop ;;
        n) echo -e "${Y}Perubahan disimpan untuk restart berikutnya.${N}"; sleep 2 ;;
    esac
}

# HAPUS UBUNTU DESKTOP BERSIH TOTAL
delete_desktop() {
    header

    echo -e "${R}HAPUS UBUNTU DESKTOP - BERSIH TOTAL${N}"
    echo
    echo "Fitur ini akan menghapus:"
    echo "- Semua container yang memakai image qemux/qemu"
    echo "- Semua image dari repository qemux/qemu"
    echo "- Seluruh data di $DIR"
    echo "- Storage, disk, dan konfigurasi Ubuntu"
    echo
    echo -e "${Y}PERINGATAN: DATA DAN CONTAINER TERKAIT AKAN DIHAPUS!${N}"
    echo

    read -p "Yakin ingin menghapus Ubuntu Desktop? [Y/N]: " jawab

    if [ "${jawab,,}" != "y" ]; then
        echo -e "${Y}Penghapusan dibatalkan.${N}"
        sleep 2
        return
    fi

    echo
    echo -e "${R}KONFIRMASI TERAKHIR${N}"
    read -p "Ketik HAPUS untuk melanjutkan: " konfirmasi

    if [ "$konfirmasi" != "HAPUS" ]; then
        echo -e "${Y}Penghapusan dibatalkan.${N}"
        sleep 2
        return
    fi

    # CEK DOCKER
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${R}Docker tidak ditemukan!${N}"
        read -p "Tekan Enter..."
        return
    fi

    if ! docker info >/dev/null 2>&1; then
        echo -e "${R}Docker daemon tidak aktif!${N}"
        read -p "Tekan Enter..."
        return
    fi

    echo
    echo -e "${Y}[1/4] Mencari image qemux/qemu...${N}"

    local IMAGE_IDS
    local CONTAINER_IDS
    local IMAGE_ID
    local CONTAINER_ID
    local FAILED=0

    IMAGE_IDS="$(docker image ls --no-trunc -q qemux/qemu 2>/dev/null | sort -u || true)"

    # HAPUS SEMUA CONTAINER YANG MENGGUNAKAN IMAGE TERSEBUT
    if [ -n "$IMAGE_IDS" ]; then
        echo
        echo -e "${Y}[2/4] Menghapus container terkait...${N}"

        while IFS= read -r IMAGE_ID; do
            [ -z "$IMAGE_ID" ] && continue

            CONTAINER_IDS="$(docker ps -aq --no-trunc --filter "ancestor=$IMAGE_ID" || true)"

            if [ -n "$CONTAINER_IDS" ]; then
                while IFS= read -r CONTAINER_ID; do
                    [ -z "$CONTAINER_ID" ] && continue

                    echo -e "${C}Menghapus container: $CONTAINER_ID${N}"

                    if ! docker rm -f "$CONTAINER_ID"; then
                        echo -e "${R}Gagal menghapus container $CONTAINER_ID${N}"
                        FAILED=1
                    fi
                done <<< "$CONTAINER_IDS"
            fi
        done <<< "$IMAGE_IDS"
    else
        echo -e "${C}Image qemux/qemu tidak ditemukan.${N}"
    fi

    # HAPUS SELURUH IMAGE REPOSITORY
    echo
    echo -e "${Y}[3/4] Menghapus image qemux/qemu...${N}"

    IMAGE_IDS="$(docker image ls --no-trunc -q qemux/qemu 2>/dev/null | sort -u || true)"

    if [ -n "$IMAGE_IDS" ]; then
        while IFS= read -r IMAGE_ID; do
            [ -z "$IMAGE_ID" ] && continue

            echo -e "${C}Menghapus image: $IMAGE_ID${N}"

            if ! docker image rm -f "$IMAGE_ID"; then
                echo -e "${R}Gagal menghapus image $IMAGE_ID${N}"
                FAILED=1
            fi
        done <<< "$IMAGE_IDS"
    fi

    # HAPUS FOLDER DATA
    echo
    echo -e "${Y}[4/4] Menghapus seluruh data Ubuntu Desktop...${N}"

    if [ -d "$DIR" ]; then
        rm -rf -- "$DIR"
    fi

    # VERIFIKASI
    echo
    echo -e "${Y}Memverifikasi hasil penghapusan...${N}"

    local REMAINING_IMAGES
    local REMAINING_CONTAINERS

    REMAINING_IMAGES="$(docker image ls --no-trunc -q qemux/qemu 2>/dev/null | sort -u || true)"
    REMAINING_CONTAINERS="$(docker ps -aq --filter "ancestor=qemux/qemu:latest" 2>/dev/null || true)"

    if [ -n "$REMAINING_IMAGES" ] || [ -n "$REMAINING_CONTAINERS" ] || [ "$FAILED" -ne 0 ]; then
        echo
        echo -e "${R}PENGHAPUSAN BELUM SEPENUHNYA BERHASIL!${N}"
        echo
        echo -e "${Y}Masih ada resource yang gagal dihapus.${N}"
        echo "Silakan periksa Docker untuk mengetahui penyebabnya."
    else
        echo
        echo -e "${G}╔══════════════════════════════════════╗${N}"
        echo -e "${G}║     UBUNTU DESKTOP BERHASIL DIHAPUS  ║${N}"
        echo -e "${G}╚══════════════════════════════════════╝${N}"
        echo
        echo -e "${G}Semua image qemux/qemu sudah tidak ditemukan.${N}"
        echo -e "${G}Container terkait sudah dibersihkan.${N}"
        echo -e "${G}Folder $DIR sudah dihapus.${N}"
    fi

    echo
    read -p "Tekan Enter untuk kembali ke menu..."
}

# MAIN MENU
main_menu() {
    while true; do
        header

        echo -e "${G}[1]${N} Bikin Ubuntu Desktop"
        echo -e "${G}[2]${N} Restart Ubuntu Desktop"
        echo -e "${G}[3]${N} Edit Spesifikasi Desktop"
        echo -e "${R}[4]${N} Hapus Ubuntu Desktop (Bersih Total)"
        echo -e "${R}[0]${N} Keluar"

        echo
        read -p "Pilih nomor: " pilih

        case "$pilih" in
            1) create_menu ;;
            2) restart_desktop ;;
            3) edit_menu ;;
            4) delete_desktop ;;
            0) exit 0 ;;
            *) echo -e "${R}Pilihan tidak tersedia!${N}"; sleep 1 ;;
        esac
    done
}

load_config
main_menu
