#!/bin/bash

# ==============================================================================
# MANZ XD - ULTIMATE CONSOLE
# ==============================================================================

# --- COLOR PALETTE (NEON THEME) ---
# Menggunakan warna terang (Bold/Bright) agar terlihat colorful
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GREY='\033[0;37m'
NC='\033[0m' # No Color

# --- UI CONSTANTS ---
# Garis panjang yang kamu suka
BORDER_H="══════════════════════════════════════════════════════════"

# --- SYSTEM FUNCTIONS ---

# Logo Generator (ManzXD)
draw_logo() {
    echo -e "${BLUE}╔${BORDER_H}╗${NC}"
    echo -e "${BLUE}║${CYAN} __  __                   ${PURPLE}   __  ______               ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}|  \/  | __ _ _ __  ____  ${PURPLE}   \ \/ /  _ \              ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}| |\/| |/ _\` | '_ \|_  /  ${PURPLE}    \  /| | | |             ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}| |  | | (_| | | | |/ /   ${PURPLE}    /  \| |_| |             ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}|_|  |_|\__,_|_| |_/___|  ${PURPLE}   /_/\_\____/              ${BLUE}║${NC}"
    echo -e "${BLUE}║${WHITE}                                                          ${BLUE}║${NC}"
    echo -e "${BLUE}║${YELLOW}              P O W E R E D   B Y   M A N Z               ${BLUE}║${NC}"
    echo -e "${BLUE}╚${BORDER_H}╝${NC}"
}

# Header Standar
draw_header() {
    clear
    draw_logo
    echo -e "\n${GREY}      SYSTEM TIME: $(date '+%H:%M:%S') | USER: $(whoami)${NC}"
    echo -e "${PURPLE}${BORDER_H}${NC}\n"
}

# Fungsi Loading Bar (Supaya terlihat keren/bagus)
loading_bar() {
    local duration=${1:-2}
    local bars=25
    local sleep_time=$(echo "$duration / $bars" | bc -l)
    
    echo -ne "${CYAN}Processing: [${NC}"
    for ((i=0; i<bars; i++)); do
        echo -ne "${GREEN}#${NC}"
        sleep 0.05
    done
    echo -e "${CYAN}] ${GREEN}Done!${NC}"
}

# Fungsi Status Box
status_msg() {
    local title="$1"
    local color="$2"
    echo -e "${color}╔${BORDER_H}╗${NC}"
    echo -e "${color}║${WHITE}  STATUS: ${title}$(printf '%*s' $((46 - ${#title})))${color}║${NC}"
    echo -e "${color}╚${BORDER_H}╝${NC}"
}

# --- MAIN LOGIC ---

while true; do
    draw_header
    
    # MENU DISPLAY
    echo -e "${CYAN}  [ MENU SELECTION ]${NC}"
    echo -e "${BLUE}  ╔════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[1]${WHITE} 🚀 GitHub VPS Maker (Docker)                 ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[2]${WHITE} 🔧 IDX Tool Setup (Config & Clean)           ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[3]${WHITE} ⚡ IDX VPS Maker (Auto Script)              ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[4]${WHITE} ❌ Exit Console                              ${BLUE}║${NC}"
    echo -e "${BLUE}  ╚════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${PURPLE}${BORDER_H}${NC}"
    echo -ne "${YELLOW}  Select Option [1-4]: ${NC}"
    read -p "" selection

    case $selection in
        1)
            draw_header
            status_msg "INITIALIZING GITHUB VPS..." "$CYAN"
            echo ""
            
            # Variables
            RAM=15000
            CPU=4
            DISK=100G
            IMG="hopingboyz/debain12"
            
            echo -e "${WHITE}  Configuration Loaded:${NC}"
            echo -e "${GREY}  > RAM : ${GREEN}${RAM}MB${NC}"
            echo -e "${GREY}  > CPU : ${GREEN}${CPU} Cores${NC}"
            echo -e "${GREY}  > IMG : ${GREEN}${IMG}${NC}"
            echo ""
            
            loading_bar
            
            # Execute
            echo -e "\n${YELLOW}  [>] Booting Container...${NC}"
            mkdir -p "$PWD/vmdata"
            docker run -it --rm \
                --name "manz_vps" \
                --device /dev/kvm \
                -v "$PWD/vmdata":/vmdata \
                -e RAM="$RAM" \
                -e CPU="$CPU" \
                -e DISK_SIZE="$DISK" \
                "$IMG"
            
            echo -e "\n${PURPLE}${BORDER_H}${NC}"
            read -n 1 -s -r -p "  Press any key to return..."
            ;;
            
        2)
            draw_header
            status_msg "SETTING UP IDX ENVIRONMENT..." "$GREEN"
            echo ""
            
            echo -e "${YELLOW}  [1/3] Cleaning workspace...${NC}"
            cd
            rm -rf myapp flutter
            mkdif -p vm
            cd vm
            sleep 0.5
            
            echo -e "${YELLOW}  [2/3] Creating directory structure...${NC}"
            mkdir -p .idx
            cd .idx
            sleep 0.5
            
            echo -e "${YELLOW}  [3/3] Generating dev.nix config...${NC}"
            cat <<EOF > dev.nix
{ pkgs, ... }: {
  channel = "stable-24.05";
  packages = with pkgs; [
    unzip
    openssh
    git
    qemu_kvm
    sudo
    cdrkit
    cloud-utils
    qemu
  ];
  env = {
    EDITOR = "nano";
  };
  idx = {
    extensions = [
      "Dart-Code.flutter"
      "Dart-Code.dart-code"
    ];
    workspace = {
      onCreate = { };
      onStart = { };
    };
  };
}
EOF
            loading_bar
            echo -e "\n${GREEN}  SUCCESS: IDX Config created at ~/vm/.idx${NC}"
            
            echo -e "\n${PURPLE}${BORDER_H}${NC}"
            read -n 1 -s -r -p "  Press any key to return..."
            ;;
            
        3)
            draw_header
            status_msg "LAUNCHING IDX VPS SCRIPT..." "$PURPLE"
            echo ""
            
            echo -e "${CYAN}  [>] Fetching script from network...${NC}"
            loading_bar
            echo -e "${CYAN}  [>] Executing payload...${NC}\n"
            
            bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vm-idx.sh)
            
            echo -e "\n${PURPLE}${BORDER_H}${NC}"
            read -n 1 -s -r -p "  Press any key to return..."
            ;;
            
        4)
            clear
            echo -e "\n${RED}╔${BORDER_H}╗${NC}"
            echo -e "${RED}║${WHITE}             SESSION TERMINATED BY USER               ${RED}║${NC}"
            echo -e "${RED}║${YELLOW}            Terima Kasih - ManzXD Corp                ${RED}║${NC}"
            echo -e "${RED}╚${BORDER_H}╝${NC}\n"
            exit 0
            ;;
            
        *)
            echo -e "\n${RED}  [!] Invalid Input. Please select 1-4.${NC}"
            sleep 1
            ;;
    esac
done
