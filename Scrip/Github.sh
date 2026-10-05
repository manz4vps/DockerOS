#!/bin/bash

# ==========================================
# CODESPACE OS SWITCHER + FULL TOOLS
# ==========================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW}   CODESPACE OS SWITCHER + FULL TOOLS     ${NC}"
echo -e "${CYAN}==========================================${NC}"
echo -e "1. Debian 11    ${GREEN}(Minimal + Tools)${NC}"
echo -e "2. Ubuntu 22.04 ${BLUE}(Minimal + Tools)${NC}"
echo -e "3. Ubuntu 24.04 ${BLUE}(Recommended + Tools)${NC}"
echo -e "4. Ubuntu 26.04 ${GREEN}(Minimal + Tools)${NC}"
echo -e "${CYAN}==========================================${NC}"

read -p "Pilih nomor OS (1-4): " pilihan

mkdir -p .devcontainer

case "$pilihan" in

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
        echo -e "${RED}❌ Pilihan tidak valid!${NC}"
        echo "Pilih angka 1-4."
        exit 1
        ;;
esac

# ==========================================
# DOCKERFILE
# ==========================================

cat > .devcontainer/Dockerfile <<EOF
FROM $OS_IMAGE

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \\
    apt-get install -y \\
    unzip \\
    openssh-client \\
    git \\
    wget \\
    curl \\
    lsof \\
    qemu-system \\
    qemu-system-x86 \\
    qemu-utils \\
    genisoimage \\
    cloud-utils \\
    cloud-image-utils \\
    && apt-get clean \\
    && rm -rf /var/lib/apt/lists/*
EOF

# ==========================================
# DEVCONTAINER.JSON
# ==========================================

cat > .devcontainer/devcontainer.json <<EOF
{
  "name": "$OS_NAME + Docker",

  "build": {
    "dockerfile": "Dockerfile"
  },

  "containerUser": "root",
  "remoteUser": "root",

  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
EOF

# ==========================================
# HASIL
# ==========================================

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}✅ BERHASIL!${NC}"
echo -e "${GREEN}==========================================${NC}"

echo -e "${YELLOW}OS              :${NC} $OS_NAME"
echo -e "${YELLOW}Base Image      :${NC} $OS_IMAGE"
echo -e "${YELLOW}User            :${NC} ROOT"
echo -e "${YELLOW}Docker          :${NC} Docker-in-Docker"
echo -e "${YELLOW}Install         :${NC} Dockerfile saat BUILD"

echo ""
echo -e "${CYAN}📦 TOOLS TERPASANG:${NC}"

echo "   • unzip"
echo "   • openssh-client"
echo "   • git"
echo "   • wget"
echo "   • curl"
echo "   • lsof"
echo "   • qemu-system"
echo "   • qemu-system-x86"
echo "   • qemu-utils"
echo "   • genisoimage"
echo "   • cloud-utils"
echo "   • cloud-image-utils"

echo ""
echo -e "${CYAN}📁 FILE:${NC}"
echo "   • .devcontainer/Dockerfile"
echo "   • .devcontainer/devcontainer.json"

echo ""
echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW}REBUILD CODESPACE:${NC}"
echo ""
echo "1. Buka Command Palette"
echo "2. Pilih: Codespaces: Rebuild Container"
echo "3. Pilih Full Rebuild jika tersedia"
echo ""
echo -e "${GREEN}==========================================${NC}"
echo ""
