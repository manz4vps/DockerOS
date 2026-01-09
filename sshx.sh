#!/bin/bash

# ==================================================
#   MANZXD SSHX ULTIMATE FIX
#   Fixes: Download Path, Input Bug, Systemd Output
# ==================================================

# 1. BERSIHKAN SYSTEM LAMA
echo -e "\033[0;34m[1/5] Membersihkan sisa error...\033[0m"
systemctl stop sshx > /dev/null 2>&1
systemctl disable sshx > /dev/null 2>&1
pkill -f sshx
rm -f /usr/local/bin/sshx /usr/local/bin/sshx-core /usr/local/bin/sshx-wrapper
rm -f /etc/systemd/system/sshx.service
rm -f /tmp/sshx_monitor.log /root/sshx_link.txt

# 2. INSTALL DEPENDENCIES & BINARY (DENGAN LOGIKA PENCARIAN FILE)
echo -e "\033[0;34m[2/5] Install Binary...\033[0m"
apt-get update -qq
apt-get install -y curl qrencode bsdutils -qq > /dev/null 2>&1

# Download Script
curl -sSf https://sshx.io/get | sh > /dev/null 2>&1

# --> FIX: Cari file sshx dimanapun dia berada <--
if [ -f "./sshx" ]; then
    mv ./sshx /usr/local/bin/sshx-core
elif [ -f "$HOME/.sshx/sshx" ]; then
    mv "$HOME/.sshx/sshx" /usr/local/bin/sshx-core
elif [ -f "/root/.sshx/sshx" ]; then
    mv "/root/.sshx/sshx" /usr/local/bin/sshx-core
else
    echo -e "\033[0;31m[ERROR] Gagal download binary sshx. Cek koneksi internet!\033[0m"
    exit 1
fi
chmod +x /usr/local/bin/sshx-core

# 3. BUAT WRAPPER SYSTEMD (DENGAN LOGGING TTY)
echo -e "\033[0;34m[3/5] Setup Wrapper Systemd...\033[0m"
cat << 'EOF' > /usr/local/bin/sshx-wrapper
#!/bin/bash
LOGFILE="/tmp/sshx_monitor.log"
LINK_FILE="/root/sshx_link.txt"

# Paksa pakai 'script' command agar output link keluar di log
# Ini solusi paling ampuh untuk sshx di background
rm -f "$LOGFILE"
script -q -c "/usr/local/bin/sshx-core" "$LOGFILE" > /dev/null 2>&1 &
PID=$!

# Loop mencari link selama 20 detik
for i in {1..20}; do
    if grep -q "sshx.io/s/" "$LOGFILE"; then
        # Ambil link dan bersihkan dari karakter aneh
        LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1 | tr -d '\r')
        echo "$LINK" > "$LINK_FILE"
        break
    fi
    sleep 1
done

wait $PID
EOF
chmod +x /usr/local/bin/sshx-wrapper

# 4. BUAT SERVICE FILE
echo -e "\033[0;34m[4/5] Mengaktifkan Service...\033[0m"
cat <<EOF > /etc/systemd/system/sshx.service
[Unit]
Description=SSHX Tunnel
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

# 5. BUAT MENU (DENGAN ANTI-SALAH PILIH)
echo -e "\033[0;34m[5/5] Membuat Menu...\033[0m"
cat << 'EOF' > /usr/local/bin/sshx
#!/bin/bash
LINK_FILE="/root/sshx_link.txt"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}      MANZXD SSHX CONTROLLER v2        ${NC}"
echo -e "${GREEN}========================================${NC}"

if systemctl is-active --quiet sshx; then
    STATUS="${GREEN}RUNNING${NC}"
else
    STATUS="${RED}STOPPED${NC}"
fi
echo -e "Status: $STATUS"
echo -e ""
echo -e "1) 👁️  Lihat QR Code & Link"
echo -e "2) 🔄 Restart SSHX"
echo -e "3) 🛑 Matikan SSHX"
echo -e "4) 🚪 Keluar"
echo -e ""

# --> FIX: Pakai read -r dan bersihkan input <--
read -p "Pilih: " raw_opt
opt=$(echo "$raw_opt" | tr -d '[:space:]')

case $opt in
    1)
        if [ -f "$LINK_FILE" ]; then
            LINK=$(cat "$LINK_FILE")
            if [[ "$LINK" == *"sshx.io"* ]]; then
                echo -e "\nLink: ${YELLOW}$LINK${NC}\n"
                qrencode -t ANSIUTF8 "$LINK"
            else
                echo -e "\n${YELLOW}Sedang generate... Tunggu 3 detik.${NC}"
            fi
        else
            echo -e "\n${RED}File link belum ada. Pastikan service jalan.${NC}"
        fi
        ;;
    2)
        systemctl restart sshx
        rm -f "$LINK_FILE"
        echo "Restarting... Cek menu 1 lagi nanti."
        ;;
    3)
        systemctl stop sshx
        echo "Service dimatikan."
        ;;
    4)
        exit
        ;;
    *)
        echo -e "\n${RED}Input tidak dikenali ($opt).${NC}"
        ;;
esac
echo ""
EOF
chmod +x /usr/local/bin/sshx

echo -e "\033[0;32mSELESAI! Silahkan ketik 'sshx' sekarang.\033[0m"
