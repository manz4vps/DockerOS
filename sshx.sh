#!/bin/bash

# SSHX Auto Setup & Background Run
# Adapted logic from Playit Script

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${YELLOW}🔄 Menyiapkan SSHX...${NC}"

# 1. Install Qrencode (Buat QR Code)
if ! command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall qrencode...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qrencode -qq
fi

# 2. Install/Update SSHX
if ! command -v sshx &>/dev/null; then
    echo -e "${YELLOW}⬇️  Mendownload SSHX...${NC}"
    curl -sSf https://sshx.io/get | sh
fi

echo -e "${YELLOW}🚀 Menjalankan SSHX di Background...${NC}"

# 3. Jalankan SSHX (Background Mode dengan nohup)
# Kita hapus log lama biar gak bingung
rm -f sshx_log.txt

# 'nohup' bikin proses gak mati pas terminal ditutup
nohup sshx > sshx_log.txt 2>&1 &
PID_SSHX=$!

# Kita tunggu sebentar memastikan process jalan
sleep 2

found=0

# --- STEP 4: CARI LINK & TAMPILKAN QR ---
# Loop ini akan mencari link sampai ketemu
while [ $found -eq 0 ]; do
    # Cek apakah process masih hidup
    if ! kill -0 $PID_SSHX 2>/dev/null; then
        echo -e "${RED}❌ SSHX mati tiba-tiba. Cek koneksi internetmu.${NC}"
        cat sshx_log.txt
        exit 1
    fi

    # Cari Link SSHX di log (Format: https://sshx.io/s/.....)
    LINK=$(grep -o 'https://sshx.io/s/[a-zA-Z0-9]*' sshx_log.txt | head -n 1)

    if [ ! -z "$LINK" ]; then
        found=1
        clear
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}      ✅  SSHX BERHASIL JALAN!  ✅      ${NC}"
        echo -e "${GREEN}=========================================${NC}"
        
        echo -e "\n${CYAN}--- SILAHKAN SCAN QR CODE INI ---${NC}"
        qrencode -t ANSIUTF8 "$LINK"
        
        echo -e "\n${CYAN}--- ATAU SALIN LINK MANUAL ---${NC}"
        echo -e "${YELLOW}$LINK${NC}"
        
        echo -e "\n${GREEN}INFO PENTING:${NC}"
        echo -e "1. SSHX berjalan di background dengan PID: ${YELLOW}$PID_SSHX${NC}"
        echo -e "2. Kamu bisa menutup script ini/terminal ini, koneksi tetap AMAN."
        echo -e "3. Untuk mematikan SSHX, ketik: ${RED}kill $PID_SSHX${NC}"
        echo -e "========================================="
    fi
    
    # Cek log setiap 1 detik
    sleep 1
done

# Script selesai, tapi SSHX tetap jalan di background.
exit 0
