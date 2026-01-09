#!/bin/bash

# ==================================================
#   AUTO INSTALLER SSHX (SYSTEMD VERSION) - FINAL FIX
# ==================================================

# 1. Bersihkan instalasi lama agar bersih
systemctl stop sshx > /dev/null 2>&1
systemctl disable sshx > /dev/null 2>&1
pkill -f sshx
pkill -f sshx-core
rm -f /usr/local/bin/sshx /usr/local/bin/sshx-core /usr/local/bin/sshx-wrapper
rm -f /etc/systemd/system/sshx.service
rm -f /tmp/sshx_monitor.log /root/sshx_link.txt

echo -e "\033[0;34m[1/5] Install Dependencies & Binary...\033[0m"
apt-get update -qq
apt-get install -y curl qrencode -qq > /dev/null 2>&1

# Download & Rename Binary
curl sSf https://sshx.io/get | sh > /dev/null 2>&1
if [ -f "./sshx" ]; then mv ./sshx /usr/local/bin/sshx-core; fi
if [ -f "$HOME/.sshx/sshx" ]; then mv "$HOME/.sshx/sshx" /usr/local/bin/sshx-core; fi
chmod +x /usr/local/bin/sshx-core

echo -e "\033[0;34m[2/5] Membuat Wrapper Script...\033[0m"
# Wrapper ini tugasnya menjalankan sshx-core dan nyatet Link ke file
cat << 'EOF' > /usr/local/bin/sshx-wrapper
#!/bin/bash
LOGFILE="/tmp/sshx_monitor.log"
LINK_FILE="/root/sshx_link.txt"

# Reset Log
echo "Generating..." > "$LINK_FILE"
rm -f "$LOGFILE"
touch "$LOGFILE"
chmod 666 "$LOGFILE"

# Jalankan SSHX Core & catat outputnya
/usr/local/bin/sshx-core > "$LOGFILE" 2>&1 &
PID=$!

# Loop sebentar untuk grab linknya
for i in {1..20}; do
    if grep -q "https://sshx.io/s/" "$LOGFILE"; then
        LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1)
        echo "$LINK" > "$LINK_FILE"
        break
    fi
    sleep 1
done

# Pastikan proses tetap jalan agar systemd tidak mati
wait $PID
EOF
chmod +x /usr/local/bin/sshx-wrapper

echo -e "\033[0;34m[3/5] Setup Systemd Service...\033[0m"
cat <<EOF > /etc/systemd/system/sshx.service
[Unit]
Description=SSHX Tunnel Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/sshx-wrapper
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sshx > /dev/null 2>&1
systemctl restart sshx

echo -e "\033[0;34m[4/5] Membuat Menu (Command: sshx)...\033[0m"
cat << 'EOF' > /usr/local/bin/sshx
#!/bin/bash
LINK_FILE="/root/sshx_link.txt"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}      MANZXD SSHX (SYSTEMD MODE)       ${NC}"
echo -e "${GREEN}========================================${NC}"

# Cek apakah service jalan
if systemctl is-active --quiet sshx; then
    STATUS="${GREEN}RUNNING${NC}"
else
    STATUS="${RED}STOPPED${NC}"
fi

echo -e "Service Status: $STATUS"
echo -e ""
echo -e "1) 👁️  Lihat QR Code & Link"
echo -e "2) 🔄 Restart Service"
echo -e "3) 🛑 Stop Service"
echo -e "4) 🚪 Exit"
echo -e ""
read -p "Pilih: " opt
case $opt in
    1)
        if [ -f "$LINK_FILE" ]; then
            CONTENT=$(cat "$LINK_FILE")
            if [[ "$CONTENT" == *"sshx.io"* ]]; then
                echo -e "\nLink: ${YELLOW}$CONTENT${NC}\n"
                qrencode -t ANSIUTF8 "$CONTENT"
            else
                echo -e "\n${YELLOW}Link belum siap/tergenerate. Tunggu sebentar...${NC}"
                echo -e "Coba pilih menu 1 lagi dalam 5 detik."
            fi
        else
            echo "File link tidak ditemukan."
        fi
        ;;
    2)
        echo "Restarting service..."
        systemctl restart sshx
        echo "Selesai. Silahkan cek menu 1."
        ;;
    3)
        systemctl stop sshx
        echo "Service dimatikan."
        ;;
    4)
        exit
        ;;
    *)
        echo "Menu tidak ada."
        ;;
esac
echo ""
EOF
chmod +x /usr/local/bin/sshx

echo -e "\033[0;32m[5/5] SELESAI! Ketik 'sshx' untuk menu.\033[0m"
