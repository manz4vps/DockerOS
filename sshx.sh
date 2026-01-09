#!/bin/bash

# SSHX Background Script - Style "Playit ManzXD"
# Modified to match your screenshot

# --- COLORS ---
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

clear
echo -e "${YELLOW}🔄 Menyiapkan SSHX...${NC}"

# 1. Cek & Install Qrencode
if ! command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall qrencode...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qrencode -qq
fi

# 2. Cek & Install SSHX
if ! command -v sshx &>/dev/null; then
    echo -e "${YELLOW}⬇️  Mendownload SSHX...${NC}"
    curl -sSf https://sshx.io/get | sh
fi

# 3. Bersihkan log lama
rm -f sshx_log.txt

# 4. Jalankan SSHX di Background (Nohup)
# Output dibuang ke sshx_log.txt supaya bisa kita baca
nohup sshx > sshx_log.txt 2>&1 &
PID_SSHX=$!

# Tunggu sebentar biar log terisi
sleep 2

found=0

# --- LOOP PENCARIAN LINK ---
while [ $found -eq 0 ]; do
    # Cek kalau process mati
    if ! kill -0 $PID_SSHX 2>/dev/null; then
        echo -e "${RED}❌ SSHX Gagal dijalankan atau mati.${NC}"
        cat sshx_log.txt
        exit 1
    fi

    # Ambil Link dari Log
    LINK=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' sshx_log.txt | head -n 1)

    if [ ! -z "$LINK" ]; then
        found=1
        clear
        
        # --- TAMPILAN SESUAI SCREENSHOT ---
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}      ✅  SSHX BERHASIL JALAN!  ✅      ${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo ""
        
        echo -e "${CYAN}--- SILAHKAN SCAN QR CODE INI ---${NC}"
        # Generate QR Code
        qrencode -t ANSIUTF8 "$LINK"
        
        echo ""
        echo -e "${CYAN}--- ATAU SALIN LINK MANUAL ---${NC}"
        echo -e "${YELLOW}$LINK${NC}"
        echo ""
        
        echo -e "${GREEN}INFO PENTING:${NC}"
        echo -e "1. SSHX berjalan di background dengan PID: ${YELLOW}$PID_SSHX${NC}"
        echo -e "2. Kamu bisa menutup script ini/terminal ini, koneksi tetap AMAN."
        echo -e "3. Untuk mematikan SSHX, ketik: ${RED}kill $PID_SSHX${NC}"
        echo -e "========================================="
        echo ""
        echo -e "${CYAN}------------------------------------------${NC}"
        
        # --- FITUR PAUSE ---
        # User harus tekan tombol dulu baru script keluar,
        # tapi SSHX tetap jalan di background.
        read -n 1 -s -r -p "Tekan sembarang tombol untuk kembali..."
        echo ""
        break
    fi
    sleep 1
done
