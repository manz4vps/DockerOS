#!/bin/bash

set -euo pipefail
clear

# -------------------------
# Warna
# -------------------------
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# -------------------------
# ASCII Logo (RISMAN)
# -------------------------
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

# -------------------------
# Show Credits (tetap)
# -------------------------
msg1="Make By Manz & Ndaa"
msg2="Docker credit by ManzXYZ"

echo -e "\033[1;32m$msg1\033[0m"
sleep 0.3
echo -e "\033[1;34m$msg2\033[0m"
sleep 2
clear

# -------------------------
# Pilih OS
# -------------------------
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
  *) echo -e "${RED}Pilihan tidak valid!${RESET}"; exit 1 ;;
esac

# -------------------------
# Input Resource
# -------------------------
echo -e "${BOLD}${CYAN}Masukkan konfigurasi resource:${RESET}"
read -rp "Limit RAM (misal 5G): " RAM
read -rp "Limit CPU (misal 2): " CPU
read -rp "Limit Disk (misal 20G): " DISK_SIZE

RAM=$(echo "$RAM" | tr '[:upper:]' '[:lower:]')
DISK_SIZE=$(echo "$DISK_SIZE" | tr '[:upper:]' '[:lower:]')

# -------------------------
# Jalankan Container
# -------------------------
VMDATA_DIR="$PWD/vmdata"
mkdir -p "$VMDATA_DIR"

echo -e "${GREEN}Menjalankan container $CONTAINER_NAME dengan RAM=$RAM CPU=$CPU DISK=$DISK_SIZE...${RESET}"
sleep 2

docker run -it --rm \
  --name "$CONTAINER_NAME" \
  --device /dev/kvm \
  -v "$VMDATA_DIR":/vmdata \
  -e RAM="$RAM" \
  -e CPU="$CPU" \
  -e DISK_SIZE="$DISK_SIZE" \
  "$IMAGE_NAME"
