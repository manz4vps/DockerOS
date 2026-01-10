#!/bin/bash

# =========================================================
# DEFINISI WARNA
# =========================================================
R='\033[0;31m'   # Red
G='\033[0;32m'   # Green
Y='\033[1;33m'   # Yellow (Bold)
W='\033[1;37m'   # White (Bold)
C='\033[0;36m'   # Cyan
N='\033[0m'      # No Color / Reset

# =========================================================
# LOGO MANZ VPS
# =========================================================
clear
echo -e "${C}  __  __                 __     __  ____  ____   ${N}"
echo -e "${C} |  \/  | __ _ _ __  ____\ \   / / |  _ \/ ___|  ${N}"
echo -e "${C} | |\/| |/ _\` | '_ \|_  / \ \ / /  | |_) \___ \  ${N}"
echo -e "${C} | |  | | (_| | | | |/ /   \ V /   |  __/ ___) | ${N}"
echo -e "${C} |_|  |_|\__,_|_| |_/___|   \_/    |_|   |____/  ${N}"
echo -e "${W}          PREMIUM VPS MANAGER SCRIPT             ${N}"
echo ""

# =========================================================
# EKSEKUSI PROGRAM
# =========================================================

echo -e "${G}[*] ${W}STARTING REAL VPS (ANY + KVM)${N}"
echo -e "${R}========================================================${N}"
echo

# Tampilan Header Box
echo -e "${C}╔════════════════════════════════════════════════════════════╗${N}"
echo -e "${C}║${W}            REAL VPS DEPLOYMENT MODULE              ${C}║${N}"
echo -e "${C}╚════════════════════════════════════════════════════════════╝${N}\n"

# Tahap 1: Persiapan Disk (dd.sh)
echo -e "${Y}🔍 Running disk & system preparation (dd.sh)...${N}"
echo -e "${Y}------------------------------------------------------------${N}"

# Jalankan dd.sh
bash <(curl -fsSL https://raw.githubusercontent.com/nobita329/The-Coding-Hub/refs/heads/main/srv/vm/dd.sh)

echo -e "\n${G}✅ Disk preparation completed.${N}\n"

# Tahap 2: Installer Utama (vm2.sh / n)
echo -e "${Y}🚀 Launching Real VPS installer (vm2.sh)...${N}"
echo -e "${Y}------------------------------------------------------------${N}"

# Jalankan installer utama
bash <(curl -fsSL https://raw.githubusercontent.com/JishnuTheGamer/Vps/refs/heads/main/n)

# Penutup
echo -e "\n${R}════════════════════════════════════════════════════════════${N}"
echo -e "${R}▶▶${W} Process Finished.${N}"
echo -e "${R}▶▶${W} Script by ManzVPS.${N}"
echo
