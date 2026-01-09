#!/bin/bash

# ==================================================
#   AUTO INSTALLER SSHX + SYSTEMD + MENU by ManzXD
#   Fixed: QR Code Support & Command Collision
# ==================================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Cek Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[!] Harap jalankan dengan root (sudo su)${NC}"
  exit
fi

# Matikan service lama jika ada biar tidak crash
systemctl stop sshx > /dev/null 2>&1
pkill sshx > /dev/null 2>&1
rm -f /usr/local/bin/sshx /usr/local/bin/sshx-menu /usr/local/bin/sshx-wrapper

echo -e "${BLUE}[1/5] Menginstall Dependencies...${NC}"
apt-get update -qq
apt-get install -y curl qrencode -qq > /dev/null 2>&1
echo -e "${GREEN}      Selesai.${NC}"

echo -e "${BLUE}[2/5] Menginstall SSHX Binary...${NC}"
curl sSf https://sshx.io/get | sh > /dev/null 2>&1
# PENTING: Rename binary asli jadi sshx-core biar nama 'sshx' bisa dipakai menu
if [ -f "./sshx" ]; then mv ./sshx /usr/local/bin/sshx-core; fi
if [ -f "$HOME/.sshx/sshx" ]; then mv "$HOME/.sshx/sshx" /usr/local/bin/sshx-core; fi
chmod +x /usr/local/bin/sshx-core
echo -e "${GREEN}      Selesai (Binary disimpan sebagai sshx-core).${NC}"

echo -e "${BLUE}[3/5] Membuat Script Wrapper (Backend)...${NC}"
cat << 'EOF' > /usr/local/bin/sshx-wrapper
#!/bin/bash
# Script ini berjalan di background oleh Systemd

LINK_FILE="/root/sshx_link.txt"
LOGFILE="/tmp/sshx_monitor.log"

# Bersihkan log lama
rm -f "$LOGFILE"
echo "Menunggu link generate..." > "$LINK_FILE"

# Jalankan SSHX CORE (Binary Asli)
/usr/local/bin/sshx-core > "$LOGFILE" 2>&1 &
SSHX_PID=$!

# Loop cari link di log
MAX=30
COUNT=0
while [ $COUNT -lt $MAX ]; do
    if grep -q "https://sshx.io/s/" "$LOGFILE"; then
        LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1)
        echo "$LINK" > "$LINK_FILE"
        chmod 644 "$LINK_FILE"
        break
    fi
    sleep 2
    ((COUNT++))
done

# Keep alive
wait $SSHX_PID
EOF
chmod +x /usr/local/bin/sshx-wrapper
echo -e "${GREEN}      Selesai.${NC}"

echo -e "${BLUE}[4/5] Mengaktifkan Systemd Service...${NC}"
cat <<EOF > /etc/systemd/system/sshx.service
[Unit]
Description=SSHX Service for ManzXD
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/sshx-wrapper
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sshx > /dev/null 2>&1
systemctl restart sshx
echo -e "${GREEN}      Service SSHX Aktif & Auto-Start.${NC}"

echo -e "${BLUE}[5/5] Membuat Menu Kontrol (Command: sshx)...${NC}"
# Disini kita namakan filenya 'sshx' agar saat diketik langsung muncul menu
cat << 'EOF' > /usr/local/bin/sshx
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
LINK_FILE="/root/sshx_link.txt"

clear
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}       MANZXD SSHX CONTROLLER          ${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "1) 👁️  Lihat QR Code & Link"
echo -e "2) 🔄 Restart SSHX (Link Baru)"
echo -e "3) 🛑 Matikan SSHX"
echo -e "4) 🚪 Keluar"
echo -e ""
read -p "Pilih: " opt
case $opt in
    1)
        if [ -f "$LINK_FILE" ]; then
            LINK=$(cat "$LINK_FILE")
            echo -e "\nLink: ${YELLOW}$LINK${NC}\n"
            # Ini perintah untuk memunculkan QR Code
            qrencode -t ANSIUTF8 "$LINK"
        else
            echo "Sedang generate link... Coba 5 detik lagi."
        fi
        ;;
    2)
        systemctl restart sshx
        echo "Sedang restart... Coba cek menu 1 dalam 5 detik."
        ;;
    3)
        systemctl stop sshx
        echo "SSHX Dimatikan."
        ;;
    4)
        exit
        ;;
    *)
        echo "Salah pilih."
        ;;
esac
echo ""
EOF
chmod +x /usr/local/bin/sshx

echo -e ""
echo -e "${YELLOW}===========================================${NC}"
echo -e "${GREEN}  INSTALASI SELESAI!  ${NC}"
echo -e "${YELLOW}===========================================${NC}"
echo -e "Sekarang ketik perintah ini untuk melihat QR:"
echo -e "👉  ${GREEN}sshx${NC}"
echo -e ""
