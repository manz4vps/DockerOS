#!/bin/bash

# =========================================================
#        CODESPACE OS SWITCHER - FULL VERSION
#        ROOT + SUDO + DOCKER + SSH + QEMU
# =========================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

clear

echo -e "${CYAN}==================================================${NC}"
echo -e "${WHITE}       CODESPACE OS SWITCHER + FULL TOOLS        ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""
echo -e "${GREEN}1.${NC} Debian 11"
echo -e "${BLUE}2.${NC} Ubuntu 22.04"
echo -e "${BLUE}3.${NC} Ubuntu 24.04 ${GREEN}(Recommended)${NC}"
echo -e "${GREEN}4.${NC} Ubuntu 26.04"
echo ""
echo -e "${CYAN}==================================================${NC}"

read -r -p "Pilih nomor OS (1-4): " pilihan

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
        echo ""
        echo -e "${RED}Pilihan tidak valid.${NC}"
        echo "Silakan jalankan ulang dan pilih angka 1-4."
        exit 1
        ;;
esac

echo ""
echo -e "${YELLOW}Membuat Dockerfile...${NC}"

# =========================================================
# DOCKERFILE
# =========================================================

cat > .devcontainer/Dockerfile <<EOF
FROM $OS_IMAGE

ENV DEBIAN_FRONTEND=noninteractive

USER root

RUN apt-get update && apt-get install -y sudo unzip openssh-client openssh-server git wget curl lsof qemu-system qemu-system-x86 qemu-utils genisoimage cloud-utils cloud-image-utils && apt-get clean && rm -rf /var/lib/apt/lists/*

USER root
EOF

# =========================================================
# DEVCONTAINER.JSON
# =========================================================

echo -e "${YELLOW}Membuat devcontainer.json...${NC}"

cat > .devcontainer/devcontainer.json <<EOF
{
  "name": "$OS_NAME + Docker",

  "build": {
    "dockerfile": "Dockerfile"
  },

  "containerUser": "root",
  "remoteUser": "root",

  "containerEnv": {
    "HOME": "/root"
  },

  "features": {
    "ghcr.io/devcontainers/features/docker-in-docker:2": {}
  }
}
EOF

# =========================================================
# SELESAI
# =========================================================

echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}             KONFIGURASI BERHASIL                ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

echo -e "${YELLOW}OS BASE       :${NC} $OS_NAME"
echo -e "${YELLOW}IMAGE         :${NC} $OS_IMAGE"
echo -e "${YELLOW}CONTAINER USER:${NC} root"
echo -e "${YELLOW}REMOTE USER   :${NC} root"
echo -e "${YELLOW}SUDO          :${NC} enabled"
echo -e "${YELLOW}DOCKER        :${NC} Docker-in-Docker"

echo ""
echo -e "${CYAN}TOOLS:${NC}"
echo "  - sudo"
echo "  - unzip"
echo "  - openssh-client"
echo "  - openssh-server"
echo "  - git"
echo "  - wget"
echo "  - curl"
echo "  - lsof"
echo "  - qemu-system"
echo "  - qemu-system-x86"
echo "  - qemu-utils"
echo "  - genisoimage"
echo "  - cloud-utils"
echo "  - cloud-image-utils"

echo ""
echo -e "${CYAN}FILES:${NC}"
echo "  - .devcontainer/Dockerfile"
echo "  - .devcontainer/devcontainer.json"

echo ""
echo -e "${CYAN}==================================================${NC}"
echo -e "${YELLOW}LANGKAH SELANJUTNYA${NC}"
echo -e "${CYAN}==================================================${NC}"
echo ""
echo "1. Buka Command Palette"
echo "2. Pilih: Codespaces: Rebuild Container"
echo "3. Jika tersedia, pilih Full Rebuild"
echo ""
echo -e "${GREEN}Setelah rebuild, cek:${NC}"
echo ""
echo "whoami"
echo "id"
echo "cat /etc/os-release"
echo "sudo --version"
echo "docker --version"
echo "git --version"
echo "qemu-system-x86_64 --version"
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}                  SELESAI BRO                    ${NC}"
echo -e "${GREEN}==================================================${NC}"
