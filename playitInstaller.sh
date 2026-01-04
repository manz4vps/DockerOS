#!/bin/bash

# Playit Setup & Claim (Auto-Stop after Claim)
# Modified by ManzXD

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${YELLOW}🔄 Menyiapkan Playit untuk Setup...${NC}"

# 1. Download Playit
if [ ! -f "./playit-linux-amd64" ]; then
    wget -q https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64
    chmod +x playit-linux-amd64
fi

# 2. Install QR Encoder
if ! command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall fitur QR Code...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qrencode -qq
fi

echo -e "${YELLOW}🚀 Menjalankan Playit... Tunggu link muncul...${NC}"

# 3. Jalankan Playit (Mode Setup)
rm -f playit_log.txt
./playit-linux-amd64 > playit_log.txt 2>&1 &
PID_PLAYIT=$!

# Pastikan Playit mati kalau script di-close paksa
trap "kill $PID_PLAYIT 2>/dev/null; exit" SIGINT SIGTERM

found=0
claimed=0

# --- STEP 1: CARI LINK & TAMPILKAN QR ---
while [ $found -eq 0 ]; do
    if ! kill -0 $PID_PLAYIT 2>/dev/null; then
        echo -e "${RED}❌ Playit mati tiba-tiba.${NC}"
        exit 1
    fi

    # Cari Link Claim
    LINK=$(grep -o 'https://playit.gg/claim/[a-zA-Z0-9-]*' playit_log.txt | head -n 1)

    if [ ! -z "$LINK" ]; then
        found=1
        clear
        echo -e "\n${GREEN}✅ SIAP UNTUK CLAIM!${NC}\n"
        
        echo -e "${CYAN}--- SILAHKAN SCAN QR CODE INI ---${NC}"
        qrencode -t ANSIUTF8 "$LINK"
        
        echo -e "\n${CYAN}--- ATAU SALIN LINK MANUAL ---${NC}"
        echo -e "${YELLOW}$LINK${NC}"
        
        echo -e "\n${YELLOW}⏳ Menunggu kamu melakukan Claim di browser...${NC}"
        echo -e "(Jangan tutup script ini sampai muncul notif berhasil)"
    fi
    sleep 2
done

# --- STEP 2: MONITORING STATUS CLAIM ---
# Kita tunggu sampai log menunjukkan tanda-tanda berhasil claim
while [ $claimed -eq 0 ]; do
    if ! kill -0 $PID_PLAYIT 2>/dev/null; then
        echo -e "${RED}❌ Playit terhenti.${NC}"
        break
    fi

    # Cek Log kalau ada kata-kata sukses
    # Biasanya Playit bilang "secret saved" atau "tunnel running" setelah claim
    if grep -qE "secret saved|tunnel running|authenticated" playit_log.txt; then
        claimed=1
        
        # --- CLAIM BERHASIL ---
        clear
        echo -e "${GREEN}=========================================${NC}"
        echo -e "${GREEN}      ✅  BERHASIL DI-CLAIM!  ✅        ${NC}"
        echo -e "${GREEN}=========================================${NC}"
        echo -e ""
        echo -e "${CYAN}Playit sudah terdaftar di akunmu.${NC}"
        echo -e "${YELLOW}Mematikan process Playit setup...${NC}"
        
        # Matikan Playit Setup
        kill $PID_PLAYIT 2>/dev/null
        rm -f playit_log.txt
        
        echo -e "${GREEN}Process Setup Selesai & Dimatikan.${NC}"
        echo -e "Sekarang kamu bisa jalankan Playit pakai script background-mu."
        echo -e ""
        read -p "Tekan Enter untuk kembali..."
    fi
    sleep 2
done
