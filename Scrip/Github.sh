#!/bin/bash

# ==========================================
# Variabel Warna biar terminal makin kece
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW}   CODESPACE OS SWITCHER + AUTO INSTALL   ${NC}"
echo -e "${CYAN}==========================================${NC}"
echo -e "1. Debian 11    ${GREEN}(Paling Ringan)${NC}"
echo -e "2. Ubuntu 22.04 ${BLUE}(LTS Klasik)${NC}"
echo -e "3. Ubuntu 24.04 ${BLUE}(LTS Modern & Stabil)${NC}"
echo -e "4. Ubuntu 26.04 ${GREEN}(LTS Paling Baru)${NC}"
echo -e "${CYAN}==========================================${NC}"
read -p "Pilih nomor OS (1-4): " pilihan

# Bikin folder .devcontainer kalau belum ada
mkdir -p .devcontainer

case $pilihan in
  1)
    OS_IMAGE="mcr.microsoft.com/devcontainers/base:bullseye"
    OS_NAME="Debian 11"
    ;;
  2)
    OS_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu-22.04"
    OS_NAME="Ubuntu 22.04"
    ;;
  3)
    OS_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu-24.04"
    OS_NAME="Ubuntu 24.04"
    ;;
  4)
    OS_IMAGE="mcr.microsoft.com/devcontainers/base:ubuntu-26.04"
    OS_NAME="Ubuntu 26.04 LTS"
    ;;
  *)
    echo -e "\n${RED}❌ Pilihan salah bro! Coba jalanin lagi dan pilih angka 1-4.${NC}\n"
    exit 1
    ;;
esac

# List paket yang mau diinstall otomatis
PACKAGES="unzip openssh-client git qemu-system-x86 qemu-utils sudo genisoimage cloud-utils"

# Tulis file devcontainer.json dengan fitur Docker-in-Docker
cat <<EOF > .devcontainer/devcontainer.json
{
    "name": "$OS_NAME + Docker",
    "image": "$OS_IMAGE",
    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {}
    },
    "postCreateCommand": "sudo apt-get update && sudo apt-get install -y $PACKAGES"
}
EOF

# Output Sukses
echo ""
echo -e "${GREEN}✅ BERHASIL! Konfigurasi ${YELLOW}$OS_NAME + Docker${GREEN} sudah siap.${NC}"
echo -e "📦 ${CYAN}Paket otomatis :${NC} unzip, ssh, git, qemu, sudo, cdrkit(genisoimage), cloud-utils."
echo -e "🐳 ${CYAN}Fitur tambahan :${NC} Docker-in-Docker (Aktif)"
echo -e "${CYAN}------------------------------------------${NC}"
echo -e "${YELLOW}Sekarang langkah terakhir lu MANUAL (Sekali aja):${NC}"
echo -e "1. Pencet ikon ${BLUE}⚙️ Gerigi (Pengaturan)${NC} di kiri bawah."
echo -e "2. Pilih ${BLUE}'Palet Perintah...' (Command Palette)${NC} atau tekan ${YELLOW}Ctrl+Shift+P / Cmd+Shift+P${NC}."
echo -e "3. Ketik ${GREEN}'Rebuild'${NC} dan pilih ${GREEN}'Codespaces: Rebuild Container'${NC}."
echo -e "4. WAJIB PILIH ${RED}'Full Rebuild'${NC}."
echo -e "${CYAN}==========================================${NC}"
echo ""
