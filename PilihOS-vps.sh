#!/bin/bash
set -euo pipefail
clear

RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

cat << "EOF"
██████╗   ██╗   ███████╗  ███╗   ███╗   █████╗   ███╗   ██╗
██╔══██╗  ██║   ██╔════╝  ████╗ ████║  ██╔══██╗  ████╗  ██║
██████╔╝  ██║   ███████╗  ██╔████╔██║  ███████║  ██╔██╗ ██║
██╔══██╗  ██║   ╚════██║  ██║╚██╔╝██║  ██╔══██║  ██║╚██╗██║
██║  ██║  ██║   ███████║  ██║ ╚═╝ ██║  ██║  ██║  ██║ ╚████║
╚═╝  ╚═╝  ╚═╝   ╚══════╝  ╚═╝     ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚═══╝
EOF
sleep 1
clear

msg1="Make By Manz & Ndaa"
msg2="Docker credit by ManzXYZ"
echo -e "\033[1;32m$msg1\033[0m"
sleep 0.3
echo -e "\033[1;34m$msg2\033[0m"
sleep 2
clear

while true; do
  echo -e "${BOLD}${CYAN}=== MENU DOCKER RISMAN ===${RESET}"
  echo -e "${YELLOW}1)${RESET} Jalankan Container Baru"
  echo -e "${YELLOW}2)${RESET} Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} Stop Container"
  echo -e "${YELLOW}4)${RESET} Hapus Container"
  echo -e "${YELLOW}5)${RESET} Masuk ke Container"
  echo -e "${YELLOW}6)${RESET} Keluar"
  read -rp "Pilih opsi (1-6): " MENU

  case "$MENU" in
    1)
      clear
      echo -e "${BOLD}${CYAN}Pilih OS yang mau dijalankan:${RESET}"
      echo -e "${YELLOW}1)${RESET} Debian 11"
      echo -e "${YELLOW}2)${RESET} Debian 12"
      echo -e "${YELLOW}3)${RESET} Ubuntu 22"
      echo -e "${YELLOW}4)${RESET} Ubuntu 24"
      read -rp "Masukkan pilihan (1/2/3/4): " OS_CHOICE

      case "$OS_CHOICE" in
        1) IMAGE_NAME="manz4vps/debian11"; CONTAINER_NAME="debian11" ;;
        2) IMAGE_NAME="manz4vps/debian12"; CONTAINER_NAME="debian12" ;;
        3) IMAGE_NAME="manz4vps/ubuntu22"; CONTAINER_NAME="ubuntu22" ;;
        4) IMAGE_NAME="manz4vps/ubuntu24"; CONTAINER_NAME="ubuntu24" ;;
        *) echo -e "${RED}Pilihan tidak valid!${RESET}"; continue ;;
      esac

      echo -e "${BOLD}${CYAN}Masukkan konfigurasi resource:${RESET}"
      read -rp "Limit RAM (misal 5G): " RAM
      read -rp "Limit CPU (misal 2): " CPU
      read -rp "Limit Disk (misal 20G): " DISK_SIZE

      RAM=$(echo "$RAM" | tr '[:upper:]' '[:lower:]')
      DISK_SIZE=$(echo "$DISK_SIZE" | tr '[:upper:]' '[:lower:]')

      VMDATA_DIR="$PWD/vmdata"
      mkdir -p "$VMDATA_DIR"

      echo -e "${GREEN}Menjalankan container $CONTAINER_NAME dengan RAM=$RAM CPU=$CPU DISK=$DISK_SIZE...${RESET}"
      sleep 2

      docker run -dit \
        --name "$CONTAINER_NAME" \
        --device /dev/kvm \
        -v "$VMDATA_DIR":/vmdata \
        -e RAM="$RAM" \
        -e CPU="$CPU" \
        -e DISK_SIZE="$DISK_SIZE" \
        "$IMAGE_NAME"

      echo -e "${GREEN}Container berhasil dijalankan!${RESET}"
      sleep 1

      # Langsung masuk ke container setelah dijalankan
      echo -e "${CYAN}Masuk otomatis ke container ${CONTAINER_NAME}...${RESET}"
      docker attach "$CONTAINER_NAME"
      ;;

    2)
      echo -e "${CYAN}Daftar container aktif:${RESET}"
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
      ;;

    3)
      docker ps --format "table {{.Names}}\t{{.Status}}"
      read -rp "Masukkan nama container yang mau di-stop: " STOP_NAME
      docker stop "$STOP_NAME" && echo -e "${YELLOW}Container $STOP_NAME dihentikan.${RESET}"
      ;;

    4)
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Masukkan nama container yang mau dihapus: " RM_NAME
      docker rm -f "$RM_NAME" && echo -e "${RED}Container $RM_NAME dihapus.${RESET}"
      ;;

    5)
      echo -e "${CYAN}Daftar container tersedia:${RESET}"
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Masukkan nama container yang mau dimasuki: " ATTACH_NAME

      if [ -z "$ATTACH_NAME" ]; then
        echo -e "${RED}Nama container tidak boleh kosong!${RESET}"
        continue
      fi

      if ! docker ps -a --format '{{.Names}}' | grep -q "^${ATTACH_NAME}$"; then
        echo -e "${RED}Container ${ATTACH_NAME} tidak ditemukan.${RESET}"
        continue
      fi

      STATUS=$(docker inspect -f '{{.State.Running}}' "$ATTACH_NAME")
      if [ "$STATUS" = "true" ]; then
        echo -e "${GREEN}Masuk ke container ${ATTACH_NAME}...${RESET}"
        docker attach "$ATTACH_NAME"
      else
        echo -e "${YELLOW}Container ${ATTACH_NAME} belum aktif, menjalankan dulu...${RESET}"
        docker start -ai "$ATTACH_NAME"
      fi
      ;;

    6)
      echo -e "${GREEN}Keluar dari script.${RESET}"
      exit 0
      ;;

    *)
      echo -e "${RED}Pilihan tidak valid!${RESET}"
      ;;
  esac

  echo
  read -rp "Tekan [Enter] untuk kembali ke menu..."
  clear
done
