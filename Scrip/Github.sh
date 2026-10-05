#!/bin/bash

# ==========================================
# Variabel Warna biar terminal makin kece
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW}   CODESPACE OS SWITCHER + AUTO INSTALL   ${NC}"
echo -e "${CYAN}==========================================${NC}"
echo -e "1. Debian 11    ${GREEN}(Minimal)${NC}"
echo -e "2. Ubuntu 22.04 ${BLUE}(Minimal)${NC}"
echo -e "3. Ubuntu 24.04 ${BLUE}(Minimal & Recommended)${NC}"
echo -e "4. Ubuntu 26.04 ${GREEN}(Minimal)${NC}"
echo -e "${CYAN}==========================================${NC}"
read -p "Pilih nomor OS (1-4): " pilihan

# Bikin folder .devcontainer kalau belum ada
mkdir -p .devcontainer

case $pilihan in
  1)
    OS_IMAGE="debian:11"
    OS_NAME="Debian 11"
    ;;
  2)
    OS_IMAGE="ubuntu:22.04"
    OS_NAME="Ubuntu 22.04"
    ;;
  3)
    OS_IMAGE="ubuntu:24.04"
    OS_NAME="Ubuntu 24.04"
    ;;
  4)
    OS_IMAGE="ubuntu:26.04"
    OS_NAME="Ubuntu 26.04"
    ;;
  *)
    echo -e "\n${RED}❌ Pilihan salah bro! Coba jalanin lagi dan pilih angka 1-4.${NC}\n"
    exit 1
    ;;
esac

# ==========================================
# PAKET WAJIB SAJA
# Tidak ada sudo / Python / Node / Java dll.
# ==========================================
PACKAGES="unzip openssh-client git qemu-system-x86 qemu-utils genisoimage cloud-utils"

# ==========================================
# Tulis devcontainer.json
# ==========================================
cat <<EOF > .devcontainer/devcontainer.json
{
    "name": "$OS_NAME + Docker",
    "image": "$OS_IMAGE",

    "containerUser": "root",
    "remoteUser": "root",

    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {}
    },

    "postCreateCommand": "apt-get update && apt-get install -y $PACKAGES && apt-get clean && rm -rf /var/lib/apt/lists/*"
}
EOF

# ==========================================
# Output sukses
# ==========================================
echo ""
echo -e "${GREEN}✅ BERHASIL!${NC}"
echo -e "${YELLOW}OS              :${NC} $OS_NAME"
echo -e "${YELLOW}User            :${NC} ROOT"
echo -e "${YELLOW}Docker          :${NC} Docker-in-Docker"
echo -e "${YELLOW}Base Image      :${NC} $OS_IMAGE"
echo -e "${YELLOW}Tool tambahan   :${NC} HANYA paket wajib"
echo ""
echo -e "${CYAN}📦 Paket:${NC}"
echo -e "   • unzip"
echo -e "   • openssh-client"
echo -e "   • git"
echo -e "   • qemu-system-x86"
echo -e "   • qemu-utils"
echo -e "   • genisoimage"
echo -e "   • cloud-utils"
echo ""
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "${YELLOW}Sekarang rebuild Codespace:${NC}"
echo -e "1. Buka ${BLUE}Command Palette${NC}"
echo -e "2. Pilih ${GREEN}Codespaces: Rebuild Container${NC}"
echo -e "3. Pilih ${RED}Full Rebuild${NC} jika tersedia"
echo -e "${CYAN}==========================================${NC}"
echo ""
