#!/bin/bash

# ==================================================
#   AUTO INSTALLER SSHX + SYSTEMD + MENU (FIXED)
#   Fix: Output Buffering pada Systemd
# ==================================================

# 1. Bersihkan instalasi lama agar bersih total
echo -e "\033[0;34m[1/5] Membersihkan sisa instalasi lama...\033[0m"
systemctl stop sshx > /dev/null 2>&1
systemctl disable sshx > /dev/null 2>&1
pkill -f sshx
pkill -f sshx-core
rm -f /usr/local/bin/sshx /usr/local/bin/sshx-core /usr/local/bin/sshx-wrapper
rm -f /etc/systemd/system/sshx.service
rm -f /tmp/sshx_monitor.log /root/sshx_link.txt

# 2. Install Dependencies
echo -e "\033[0;34m[2/5] Install Dependencies...\033[0m"
apt-get update -qq
# Kita butuh 'bsdutils' atau 'util-linux' untuk perintah 'script'
apt-get install -y curl qrencode bsdutils -qq > /dev/null 2>&1

# 3. Download & Rename Binary
echo -e "\033[0;34m[3/5] Setup SSHX Binary...\033[0m"
curl sSf https://sshx.io/get | sh > /dev/null 2>&1
# Pindahkan dan rename jadi sshx-core
if [ -f "./sshx" ]; then mv ./sshx /usr/local/bin/sshx-core; fi
if [ -f "$HOME/.sshx/sshx" ]; then mv "$HOME/.sshx/sshx" /usr/local/bin/sshx-core; fi
chmod +x /usr/local/bin/sshx-core

# 4. Membuat Wrapper Script (JANTUNG PERBAIKANNYA DISINI)
echo -e "\033[0;34m[4/5] Membuat Systemd Wrapper...\033[0m"
cat << 'EOF' > /usr/local/bin/sshx-wrapper
#!/bin/bash

LOGFILE="/tmp/sshx_monitor.log"
LINK_FILE="/root/sshx_link.txt"
BINARY="/usr/local/bin/sshx-core"

# Reset file
echo "Generating..." > "$LINK_FILE"
rm -f "$LOGFILE"

# TRIK: Gunakan perintah 'script' untuk memalsukan terminal (TTY)
# Ini memaksa sshx mengeluarkan link seketika meskipun di background
script -q -c "$BINARY" "$LOGFILE" > /dev/null 2>&1 &
PID=$!

# Loop pencari link (Maksimal 30 detik)
for i in {1..30}; do
    if grep -q "sshx.io/s/" "$LOGFILE"; then
        # Ambil link dan bersihkan dari karakter aneh/warna (ANSI codes)
        RAW_LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1)
        # Hapus carriage return (\r) agar variabel bersih
        CLEAN_LINK=$(echo "$RAW_LINK" | tr -d '\r')
        
        echo "$CLEAN_LINK" > "$LINK_FILE"
        chmod 644 "$LINK_FILE"
        break
    fi
    sleep 1
done

# Keep alive untuk systemd
wait $PID
EOF
chmod +x /usr/local/bin/sshx-wrapper

# 5. Setup Systemd Service
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

# 6. Membuat Menu Kontrol
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
echo -e "${YELLOW}      MANZXD SSHX (SYSTEMD FIXED)      ${NC}"
echo -e "${GREEN}========================================${NC}"

# Cek Status Service
if systemctl is-active --quiet sshx; then
    STATUS="${GREEN}RUNNING${NC}"
else
    STATUS="${RED}STOPPED${NC}"
fi

echo -e "Status Service: $STATUS"
echo -e ""
echo -e "1) 👁️  Lihat QR Code & Link"
echo -e "2) 🔄 Restart SSHX (Ganti Link)"
echo -e "3) 🛑 Matikan SSHX"
echo -e "4) 🚪 Keluar"
echo -e ""
read -p "Pilih: " opt
case $opt in
    1)
        if [ -f "$LINK_FILE" ]; then
            LINK=$(cat "$LINK_FILE")
            # Cek validitas link
            if [[ "$LINK" == *"sshx.io"* ]]; then
                echo -e "\nLink: ${YELLOW}$LINK${NC}\n"
                qrencode -t ANSIUTF8 "$LINK"
            else
                echo -e "\n${YELLOW}Sedang generate link... Tunggu 3 detik dan coba lagi.${NC}"
            fi
        else
            echo "File link belum ada. Pastikan service jalan."
        fi
        ;;
    2)
        echo "Restarting service..."
        systemctl restart sshx
        # Reset file link biar user tau lagi loading
        echo "Generating..." > "$LINK_FILE" 
        echo "Selesai. Tunggu 5 detik lalu cek menu 1."
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
echo -e "\033[0;32mINSTALASI BERES!\033[0m"
echo -e "Ketik perintah: \033[1;33msshx\033[0m"
echo -e "Lalu pilih nomor 1."
