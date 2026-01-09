#!/bin/bash

# ==================================================
#   MANZXD SSHX FIXER (SYSTEMD + INPUT SANITIZER)
# ==================================================

# 1. Matikan proses yang nyangkut
echo "Membersihkan sistem..."
systemctl stop sshx > /dev/null 2>&1
pkill -f sshx
rm -f /usr/local/bin/sshx /usr/local/bin/sshx-wrapper /root/sshx_link.txt /tmp/sshx_monitor.log

# 2. Download Binary (Jika belum ada)
if [ ! -f "/usr/local/bin/sshx-core" ]; then
    echo "Download sshx..."
    curl -sSf https://sshx.io/get | sh > /dev/null 2>&1
    mv ./sshx /usr/local/bin/sshx-core
    chmod +x /usr/local/bin/sshx-core
fi

# 3. Buat Wrapper (Penyebab Link Gak Muncul Diperbaiki Disini)
# Kita pakai 'script' agar sshx mengira dia berjalan di terminal asli
cat << 'EOF' > /usr/local/bin/sshx-wrapper
#!/bin/bash
LOGFILE="/tmp/sshx_monitor.log"
LINK_FILE="/root/sshx_link.txt"

# Hapus log lama
rm -f "$LOGFILE"

# JALANKAN SSHX DENGAN PSEUDO-TTY (PENTING!)
script -q -c "/usr/local/bin/sshx-core" "$LOGFILE" > /dev/null 2>&1 &
PID=$!

# Loop pencari link (Max 20 detik)
for i in {1..20}; do
    if grep -q "sshx.io/s/" "$LOGFILE"; then
        # Ambil link dan bersihkan warnanya
        LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1 | tr -d '\r')
        echo "$LINK" > "$LINK_FILE"
        break
    fi
    sleep 1
done

wait $PID
EOF
chmod +x /usr/local/bin/sshx-wrapper

# 4. Buat Service Systemd
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

# 5. Buat Menu (Penyebab "Salah Pilih" Diperbaiki Disini)
cat << 'EOF' > /usr/local/bin/sshx
#!/bin/bash
LINK_FILE="/root/sshx_link.txt"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${GREEN}========================================${NC}"
echo -e "${YELLOW}      MANZXD SSHX (FINAL VERSION)      ${NC}"
echo -e "${GREEN}========================================${NC}"

# Cek Status
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

# MENGGUNAKAN READ TANPA -p AGAR LEBIH STABIL
echo -n "Pilih opsi [1-4]: "
read -r opt_raw

# BERSIHKAN INPUT DARI KARAKTER HANTU/SPASI
opt=$(echo "$opt_raw" | tr -d '[:space:]')

case $opt in
    1)
        if [ -f "$LINK_FILE" ]; then
            LINK=$(cat "$LINK_FILE")
            # Cek apakah link valid
            if [[ "$LINK" == *"sshx.io"* ]]; then
                echo -e "\nLink: ${YELLOW}$LINK${NC}\n"
                qrencode -t ANSIUTF8 "$LINK"
            else
                echo -e "\n${RED}Link belum siap.${NC}"
                echo -e "Isi Log Terakhir:"
                tail -n 3 /tmp/sshx_monitor.log
            fi
        else
            echo -e "\n${YELLOW}Sedang mengambil link... Tunggu 3 detik.${NC}"
        fi
        ;;
    2)
        systemctl restart sshx
        rm -f "$LINK_FILE"
        echo "Sedang restart... Silahkan cek menu 1 lagi nanti."
        ;;
    3)
        systemctl stop sshx
        echo "Service dimatikan."
        ;;
    4)
        exit
        ;;
    *)
        echo -e "\n${RED}Salah pilih bos! Kamu ketik: '$opt'${NC}"
        ;;
esac
echo ""
EOF
chmod +x /usr/local/bin/sshx

echo -e "${GREEN}Selesai! Ketik 'sshx' sekarang.${NC}"
