#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DIR="/root/gate-lite"

# Fungsi Header
show_header() {
    clear
    echo -e "${CYAN}#############################################${NC}"
    echo -e "${CYAN}#       MINEKUBE GATE LITE MANAGER          #${NC}"
    echo -e "${CYAN}#############################################${NC}"
    echo ""
}

# Cek Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Jalankan sebagai root! (sudo ./minekube-menu.sh)${NC}"
  exit
fi

show_header
echo -e "Silakan pilih menu:"
echo -e "${GREEN}[1]${NC} Install Baru / Reset Ulang (Hapus semua setting)"
echo -e "${GREEN}[2]${NC} Ganti Nama Endpoint Saja (Token & Port tetap)"
echo -e "${GREEN}[3]${NC} Ganti Token Saja (Nama & Port tetap)"
echo -e "${GREEN}[4]${NC} Ganti Port Minecraft Backend (Nama & Token tetap)"
echo -e "${RED}[0]${NC} Batal / Keluar"
echo ""
read -p "Pilihanmu (0-4): " OPTION

# === LOGIKA MENU ===

if [ "$OPTION" == "0" ]; then
    echo -e "${YELLOW}Dibatalkan.${NC}"
    exit 0

elif [ "$OPTION" == "1" ]; then
    # --- INSTALL BARU ---
    show_header
    echo -e "${GREEN}=== INSTALL BARU / RESET ===${NC}"
    echo -e "${YELLOW}PERINGATAN: Setting lama akan dihapus!${NC}"
    echo ""
    
    echo -e "Masukkan TOKEN Minekube:"
    read -p "> " TOKEN
    echo -e "Masukkan Nama Endpoint (contoh: manzxd-server):"
    read -p "> " ENDPOINT_NAME
    echo -e "Masukkan Port Server Minecraft (Default 25565):"
    read -p "> " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-25565} 

    # Bersih-bersih
    systemctl stop gate 2>/dev/null
    rm -rf "$DIR"
    mkdir -p "$DIR"
    cd "$DIR"

    # Download
    ARCH=$(uname -m)
    echo -e "${GREEN}[+] Download Gate ($ARCH)...${NC}"
    if [[ "$ARCH" == "x86_64" ]]; then
        wget -q -O gate https://github.com/minekube/gate/releases/download/v0.62.1/gate_0.62.1_linux_amd64
    elif [[ "$ARCH" == "aarch64" ]]; then
        wget -q -O gate https://github.com/minekube/gate/releases/download/v0.62.1/gate_0.62.1_linux_arm64
    fi
    chmod +x gate

    # Create Files
    echo -e "${GREEN}[+] Membuat Config...${NC}"
    echo "{\"token\": \"$TOKEN\"}" > connect.json
    
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $ENDPOINT_NAME
config:
  bind: 0.0.0.0:25500
  lite:
    enabled: true
    routes:
      - host: '*'
        backend: localhost:$BACKEND_PORT
        proxyProtocol: false
EOF

    # Service
    echo -e "${GREEN}[+] Setup Service...${NC}"
    cat <<EOF > /etc/systemd/system/gate.service
[Unit]
Description=Minekube Gate Lite Service
After=network.target
[Service]
User=root
WorkingDirectory=$DIR
ExecStart=$DIR/gate -c config.yml
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable gate
    systemctl start gate
    echo -e "${GREEN}✅ Selesai! Server direset dan dijalankan.${NC}"

elif [ "$OPTION" == "2" ]; then
    # --- EDIT ENDPOINT SAJA ---
    if [ ! -f "$DIR/config.yml" ]; then
        echo -e "${RED}[!] Belum ada installasi! Pilih menu 1 dulu.${NC}"
        exit 1
    fi
    
    show_header
    echo -e "${GREEN}=== GANTI NAMA ENDPOINT ===${NC}"
    
    # Ambil port lama biar gak ilang
    OLD_PORT=$(grep "backend:" $DIR/config.yml | awk -F: '{print $3}')
    OLD_NAME=$(grep "name:" $DIR/config.yml | awk '{print $2}')
    
    echo -e "Nama Lama : ${CYAN}$OLD_NAME${NC}"
    echo -e "Port Tetap: ${CYAN}$OLD_PORT${NC}"
    echo ""
    echo -e "Masukkan Nama Endpoint BARU:"
    read -p "> " NEW_NAME
    
    cd "$DIR"
    # Rewrite config (Token aman di connect.json gak disentuh)
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $NEW_NAME
config:
  bind: 0.0.0.0:25500
  lite:
    enabled: true
    routes:
      - host: '*'
        backend: localhost:$OLD_PORT
        proxyProtocol: false
EOF

    systemctl restart gate
    echo -e "${GREEN}✅ Nama Endpoint diganti jadi: $NEW_NAME${NC}"

elif [ "$OPTION" == "3" ]; then
    # --- EDIT TOKEN SAJA ---
    if [ ! -f "$DIR/connect.json" ]; then
        echo -e "${RED}[!] Belum ada installasi! Pilih menu 1 dulu.${NC}"
        exit 1
    fi
    
    show_header
    echo -e "${GREEN}=== GANTI TOKEN ===${NC}"
    echo -e "${YELLOW}(Nama endpoint & port tidak akan berubah)${NC}"
    echo ""
    echo -e "Masukkan TOKEN BARU:"
    read -p "> " NEW_TOKEN
    
    cd "$DIR"
    # Rewrite connect.json saja
    echo "{\"token\": \"$NEW_TOKEN\"}" > connect.json
    
    systemctl restart gate
    echo -e "${GREEN}✅ Token berhasil diperbarui!${NC}"

elif [ "$OPTION" == "4" ]; then
    # --- EDIT PORT BACKEND ---
    if [ ! -f "$DIR/config.yml" ]; then
        echo -e "${RED}[!] Belum ada installasi! Pilih menu 1 dulu.${NC}"
        exit 1
    fi

    show_header
    echo -e "${GREEN}=== GANTI PORT BACKEND ===${NC}"
    
    OLD_NAME=$(grep "name:" $DIR/config.yml | awk '{print $2}')
    
    echo -e "Nama Tetap: ${CYAN}$OLD_NAME${NC}"
    echo ""
    echo -e "Masukkan Port Server Minecraft BARU:"
    read -p "> " NEW_PORT
    
    cd "$DIR"
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $OLD_NAME
config:
  bind: 0.0.0.0:25500
  lite:
    enabled: true
    routes:
      - host: '*'
        backend: localhost:$NEW_PORT
        proxyProtocol: false
EOF

    systemctl restart gate
    echo -e "${GREEN}✅ Port berhasil diganti ke $NEW_PORT!${NC}"

else
    echo -e "${RED}Pilihan tidak valid.${NC}"
fi
