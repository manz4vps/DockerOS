#!/bin/bash

# Playit Setup & Claim (Fixed No-Freeze)
# Modified by ManzXD & Gemini

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${YELLOW}🔄 Menyiapkan Playit untuk Setup...${NC}"

# 1. Download Playit (Cek dulu biar gak download ulang)
if [ ! -f "./playit-linux-amd64" ]; then
    echo -e "${CYAN}Downloading Playit Agent...${NC}"
    wget -q https://github.com/playit-cloud/playit-agent/releases/download/v0.15.1/playit-linux-amd64
    chmod +x playit-linux-amd64
fi

# 2. Install QR Encoder (Cek dulu)
if ! command -v qrencode &>/dev/null; then
    echo -e "${YELLOW}📦 Menginstall fitur QR Code...${NC}"
    sudo apt-get update -qq && sudo apt-get install -y qrencode -qq
fi

echo -e "${YELLOW}🚀 Menjalankan Playit... Tunggu link muncul...${NC}"

# 3. Jalankan Playit (Mode Setup)
# Hapus log lama
rm -f playit_log.txt
# Jalankan di background
./playit-linux-amd64 > playit_log.txt 2>&1 &
PID_PLAYIT=$!

# Safety: Matikan playit kalau script di-close paksa
trap "kill $PID_PLAYIT 2>/dev/null; exit" SIGINT SIGTERM

found=0
claimed=0

# --- STEP 1: CARI LINK & TAMPILKAN QR ---
# Loop max 30 detik buat cari link
TIMEOUT=0
while [ $found -eq 0 ]; do
    if ! kill -0 $PID_PLAYIT 2>/dev/null; then
        echo -e "${RED}❌ Playit mati tiba-tiba. Cek koneksi/VPS.${NC}"
        exit 1
    fi

    # Cari Link Claim di log
    LINK=$(grep -o 'https://playit.gg/claim/[a-zA-Z0-9-]*' playit_log.txt | head -n 1)

    if [ ! -z "$LINK" ]; then
        found=1
        clear
        echo -e "\n${GREEN}✅ SIAP UNTUK CLAIM!${NC}\n"
        
        echo -e "${CYAN}--- SCAN QR CODE DI BAWAH ---${NC}"
        qrencode -t ANSIUTF8 "$LINK"
        
        echo -e "\n${CYAN}--- ATAU SALIN LINK MANUAL ---${NC}"
        echo -e "${YELLOW}$LINK${NC}"
        
        echo -e "\n${GREEN}=============================================${NC}"
        echo -e " ⏳  SILAHKAN BUKA LINK DI BROWSER HP/PC KAMU"
        echo -e " 👉  SETELAH CLAIM BERHASIL, TUNGGU SEBENTAR..."
        echo -e "${GREEN}=============================================${NC}"
        echo -e "${RED}[!] Kalau sudah Claim tapi script diam saja,"
        echo -e "[!] TEKAN [ENTER] UNTUK LANJUT MANUAL.${NC}"
    fi

    sleep 1
    TIMEOUT=$((TIMEOUT+1))
    if [ $TIMEOUT -gt 30 ] && [ $found -eq 0 ]; then
        echo -e "${RED}Gagal mendapatkan link claim. Coba jalankan ulang.${NC}"
        kill $PID_PLAYIT
        exit 1
    fi
done

# --- STEP 2: MONITORING STATUS CLAIM (ANTI FREEZE) ---
while [ $claimed -eq 0 ]; do
    # 1. Cek User Input (Tekan Enter buat paksa lanjut)
    # read -t 1 artinya nunggu 1 detik, kalau user tekan enter, $? jadi 0
    read -t 1 -n 1 key
    if [ $? -eq 0 ]; then
        echo -e "\n${YELLOW}⏩ Melanjutkan secara manual...${NC}"
        claimed=1
        break
    fi

    # 2. Cek apakah process masih hidup
    if ! kill -0 $PID_PLAYIT 2>/dev/null; then
        echo -e "${RED}❌ Playit terhenti.${NC}"
        break
    fi

    # 3. Cek Log Otomatis
    if grep -qE "secret saved|tunnel running|authenticated|setup complete" playit_log.txt; then
        claimed=1
        break
    fi
    
    # Animasi loading biar gak dikira freeze
    echo -n "."
done

# --- STEP 3: SELESAI ---
echo -e "\n"
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}      ✅  SETUP PLAYIT SELESAI  ✅       ${NC}"
echo -e "${GREEN}=========================================${NC}"

# Matikan process setup sementara
kill $PID_PLAYIT 2>/dev/null
rm -f playit_log.txt

echo -e "${CYAN}Process setup dimatikan. Playit sudah terdaftar.${NC}"
echo -e "${YELLOW}Script akan kembali otomatis dalam 3 detik...${NC}"
sleep 3
# Script exit otomatis di sini
