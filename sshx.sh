#!/bin/bash

# ==================================================
#   SSHX LAUNCHER (PLAYIT LOGIC ADAPTATION)
#   Fixed by ManzXD
# ==================================================

# Warna
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

# File & Binary
LOGFILE="/root/sshx_session.log"
BINARY_PATH="/usr/local/bin/sshx-core"
SCRIPT_PATH="/usr/local/bin/sshx"

# 1. Bersihkan Proses Lama (PENTING)
pkill -f sshx-core > /dev/null 2>&1
pkill -f sshx > /dev/null 2>&1
# Hapus service systemd yang bikin error kemarin
systemctl stop sshx > /dev/null 2>&1
systemctl disable sshx > /dev/null 2>&1
rm -f /etc/systemd/system/sshx.service

clear
echo -e "${YELLOW}🔄 Menyiapkan SSHX (Logic Playit)...${NC}"

# 2. Pastikan Binary SSHX Ada & Benar
if [ ! -f "$BINARY_PATH" ]; then
    echo -e "${CYAN}Download ulang binary SSHX...${NC}"
    # Pindahkan binary asli kalau masih bernama 'sshx' di folder lain
    if [ -f "/usr/local/bin/sshx" ] && [ ! -f "$BINARY_PATH" ]; then
        mv /usr/local/bin/sshx "$BINARY_PATH"
    else
        curl -sSf https://sshx.io/get | sh > /dev/null 2>&1
        mv ./sshx "$BINARY_PATH" 2>/dev/null || mv $HOME/.sshx/sshx "$BINARY_PATH"
    fi
    chmod +x "$BINARY_PATH"
fi

# 3. Install QR Encoder (jika belum ada)
if ! command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall qrencode...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qrencode -qq > /dev/null 2>&1
fi

# 4. Buat Script Menu Utama (sshx)
# Ini agar kamu bisa ketik 'sshx' kapan saja untuk menyalakan ulang
cat << 'EOF' > "$SCRIPT_PATH"
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'
LOGFILE="/root/sshx_session.log"
BINARY="/usr/local/bin/sshx-core"

clear
echo -e "${YELLOW}🚀 Menjalankan SSHX... Tunggu link muncul...${NC}"

# Matikan sesi lama biar tidak bentrok
pkill -f sshx-core > /dev/null 2>&1
rm -f "$LOGFILE"

# JALANKAN SSHX (Persis cara Playit)
nohup $BINARY > "$LOGFILE" 2>&1 &
PID_SSHX=$!

# Trap agar kalau di CTRL+C, proses background ikut mati (Opsional, tapi aman)
# trap "kill $PID_SSHX 2>/dev/null; exit" SIGINT SIGTERM

found=0
MAX_RETRIES=20
COUNT=0

# --- STEP 1: CARI LINK & TAMPILKAN QR ---
while [ $found -eq 0 ]; do
    if ! kill -0 $PID_SSHX 2>/dev/null; then
        echo -e "${RED}❌ SSHX mati tiba-tiba. Cek log: $LOGFILE${NC}"
        cat "$LOGFILE"
        exit 1
    fi

    # Cari Link (Pola Regex SSHX)
    if grep -q "https://sshx.io/s/" "$LOGFILE"; then
        LINK=$(grep -o 'https://sshx.io/s/[^ ]*' "$LOGFILE" | head -n 1)
        
        if [ ! -z "$LINK" ]; then
            found=1
            clear
            echo -e "${GREEN}=========================================${NC}"
            echo -e "${GREEN}      ✅  SSHX BERHASIL DIJALANKAN  ✅     ${NC}"
            echo -e "${GREEN}=========================================${NC}"
            echo -e ""
            
            echo -e "${CYAN}--- SCAN QR CODE DI BAWAH ---${NC}"
            qrencode -t ANSIUTF8 "$LINK"
            
            echo -e "\n${CYAN}--- ATAU SALIN LINK MANUAL ---${NC}"
            echo -e "🔗 Link: ${YELLOW}$LINK${NC}"
            echo -e ""
            echo -e "${GREEN}NOTE:${NC} Jangan matikan terminal ini atau ketik CTRL+C."
            echo -e "SSHX sedang berjalan di background (PID: $PID_SSHX)."
            echo -e "Untuk keluar menu tapi SSHX tetap jalan, tutup tab saja."
        fi
    fi
    
    sleep 1
    ((COUNT++))
    
    if [ $COUNT -ge $MAX_RETRIES ]; then
        echo -e "${RED}⚠️  Timeout: Link tidak muncul dalam 20 detik.${NC}"
        echo "Isi Log Terakhir:"
        tail -n 5 "$LOGFILE"
        exit 1
    fi
done
EOF

chmod +x "$SCRIPT_PATH"

# 5. Langsung jalankan menu baru
exec "$SCRIPT_PATH"
