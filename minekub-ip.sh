#!/bin/bash

# Warna
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

DIR="/root/gate-lite"

# Cek Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Jalankan sebagai root! (sudo ./minekube-menu.sh)${NC}"
  exit
fi

clear
echo -e "${CYAN}=== MINEKUBE MANAGER (AUTO-DETECT) ===${NC}"
echo -e "${GREEN}[1]${NC} Install / Reset Config (Otomatis Cek File)"
echo -e "${GREEN}[2]${NC} Ganti Nama Endpoint Saja"
echo -e "${GREEN}[3]${NC} Ganti Token Saja"
echo -e "${GREEN}[4]${NC} Ganti Port Minecraft Backend"
echo -e "${RED}[0]${NC} Keluar"
echo ""
read -p "Pilihan: " OPTION

if [ "$OPTION" == "0" ]; then
    exit 0

elif [ "$OPTION" == "1" ]; then
    # --- INSTALL / RESET ---
    echo -e ""
    echo -e "${GREEN}--- SETUP BARU ---${NC}"
    
    # 1. Input Data Dulu
    echo -e "Masukkan TOKEN Minekube:"
    read -p "> " TOKEN
    echo -e "Masukkan Nama Endpoint (contoh: manzxd-server):"
    read -p "> " ENDPOINT_NAME
    echo -e "Masukkan Port Server Minecraft (Default 25565):"
    read -p "> " BACKEND_PORT
    BACKEND_PORT=${BACKEND_PORT:-25565} 

    # 2. Siapkan Folder (Tanpa hapus file gate kalo ada)
    if [ ! -d "$DIR" ]; then
        mkdir -p "$DIR"
    fi
    
    # 3. LOGIKA AUTO-DETECT DOWNLOAD
    cd "$DIR"
    if [ -f "gate" ]; then
        echo -e "${CYAN}[INFO] File 'gate' sudah ada. Melewati proses download.${NC}"
    else
        echo -e "${YELLOW}[INFO] File 'gate' belum ada. Mendownload...${NC}"
        ARCH=$(uname -m)
        if [[ "$ARCH" == "x86_64" ]]; then
             wget -q -O gate https://github.com/minekube/gate/releases/download/v0.62.1/gate_0.62.1_linux_amd64 || wget -q -O gate https://github.com/minekube/gate/releases/download/v0.41.2/gate_linux_amd64
        elif [[ "$ARCH" == "aarch64" ]]; then
             wget -q -O gate https://github.com/minekube/gate/releases/download/v0.62.1/gate_0.62.1_linux_arm64 || wget -q -O gate https://github.com/minekube/gate/releases/download/v0.41.2/gate_linux_arm64
        fi
        chmod +x gate
        echo -e "${GREEN}[OK] Download selesai.${NC}"
    fi

    # 4. Matikan service lama (kalo ada) buat update config
    systemctl stop gate 2>/dev/null

    # 5. Buat File Config (Offline Mode: TRUE)
    echo "{\"token\": \"$TOKEN\"}" > connect.json
    
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $ENDPOINT_NAME
  allowOfflineModePlayers: true
config:
  bind: 0.0.0.0:25500
  lite:
    enabled: true
    routes:
      - host: '*'
        backend: localhost:$BACKEND_PORT
        proxyProtocol: false
EOF

    # 6. Setup Service Systemd
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
    
    echo -e ""
    echo -e "${GREEN}✅ SUKSES! Server sudah berjalan.${NC}"
    echo -e "IP: $ENDPOINT_NAME.play.minekube.net"

elif [ "$OPTION" == "2" ]; then
    # --- GANTI NAMA ---
    if [ ! -f "$DIR/config.yml" ]; then echo "Belum install!"; exit 1; fi
    
    OLD_PORT=$(grep "backend:" $DIR/config.yml | awk -F: '{print $3}')
    echo -e "Masukkan Nama Endpoint BARU:"
    read -p "> " NEW_NAME
    
    cd "$DIR"
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $NEW_NAME
  allowOfflineModePlayers: true
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
    echo -e "${GREEN}✅ Nama diganti jadi: $NEW_NAME${NC}"

elif [ "$OPTION" == "3" ]; then
    # --- GANTI TOKEN ---
    if [ ! -f "$DIR/connect.json" ]; then echo "Belum install!"; exit 1; fi
    echo -e "Masukkan TOKEN BARU:"
    read -p "> " NEW_TOKEN
    echo "{\"token\": \"$NEW_TOKEN\"}" > "$DIR/connect.json"
    systemctl restart gate
    echo -e "${GREEN}✅ Token diperbarui!${NC}"

elif [ "$OPTION" == "4" ]; then
    # --- GANTI PORT ---
    if [ ! -f "$DIR/config.yml" ]; then echo "Belum install!"; exit 1; fi
    OLD_NAME=$(grep "name:" $DIR/config.yml | awk '{print $2}')
    echo -e "Masukkan Port Server Minecraft BARU:"
    read -p "> " NEW_PORT
    
    cd "$DIR"
    cat <<EOF > config.yml
connect:
  enabled: true
  name: $OLD_NAME
  allowOfflineModePlayers: true
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
    echo -e "${GREEN}✅ Port diganti ke $NEW_PORT!${NC}"

else
    echo "Pilihan salah."
fi
