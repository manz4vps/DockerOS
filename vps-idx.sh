#!/bin/bash

# ==============================================================================
# MANZ XD - ULTIMATE CONSOLE (V2 - AutoStart Added)
# ==============================================================================

# --- COLOR PALETTE (NEON THEME) ---
CYAN='\033[1;36m'
PURPLE='\033[1;35m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
RED='\033[1;31m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GREY='\033[0;37m'
NC='\033[0m' # No Color

# --- SYSTEM FUNCTIONS ---

draw_logo() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN}   __  __                    ${PURPLE}   __  ______             ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}  |  \/  | __ _ _ __  ____  ${PURPLE}   \ \/ /  _ \            ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}  | |\/| |/ _\` | '_ \|_  /  ${PURPLE}    \  /| | | |          ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}  | |  | | (_| | | | |/ /   ${PURPLE}    /  \| |_| |           ${BLUE}║${NC}"
    echo -e "${BLUE}║${CYAN}  |_|  |_|\__,_|_| |_/___|  ${PURPLE}   /_/\_\____/            ${BLUE}║${NC}"
    echo -e "${BLUE}║${WHITE}                                                        ${BLUE}║${NC}"
    echo -e "${BLUE}║${YELLOW}            P O W E R E D   B Y   M A N Z               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
}

draw_header() {
    clear
    draw_logo
    echo -e "\n${GREY}      SYSTEM TIME: $(date '+%H:%M:%S') | USER: $(whoami)${NC}"
}

loading_bar() {
    local duration=${1:-2}
    local bars=25
    local sleep_time=$(awk "BEGIN {print $duration / $bars}")
    echo -ne "${CYAN}Processing: ${WHITE}[${NC}"
    for ((i=0; i<bars; i++)); do
        echo -ne "${GREEN}#${NC}"
        sleep $sleep_time
    done
    echo -e "${WHITE}] ${GREEN}Done!${NC}"
}

status_msg() {
    local title="$1"
    local color="$2"
    echo -e "${color}==================== ${title} ====================${NC}"
}

# --- MAIN LOGIC ---

while true; do
    draw_header

    echo -e "${CYAN}  [ MENU SELECTION ]${NC}"
    echo -e "${BLUE}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[1]${WHITE} 🚀 GitHub VPS Maker (Docker)                 ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[2]${WHITE} 🔧 IDX Tool Setup (Config & Clean)           ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[3]${WHITE} ⚡ IDX VPS Maker (Auto Script)               ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[4]${WHITE} 🤖 Setup Auto-Start VM (Pasang Otomatis)     ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[5]${WHITE} ❌ Exit Console                               ${BLUE}║${NC}"
    echo -e "${BLUE}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Select Option [1-5]: ${NC}"
    read selection

    case $selection in
        1)
            draw_header
            status_msg "INITIALIZING GITHUB VPS..."
            echo ""

            RAM=15000
            CPU=4
            DISK=100G
            IMG="hopingboyz/debain12"

            loading_bar

            mkdir -p "$PWD/vmdata"
            docker run -it --rm \
                --name "manz_vps" \
                --device /dev/kvm \
                -v "$PWD/vmdata":/vmdata \
                -e RAM="$RAM" \
                -e CPU="$CPU" \
                -e DISK_SIZE="$DISK" \
                "$IMG"

            read -n 1 -s -r -p "Press any key..."
            ;;

        2)
            draw_header
            status_msg "SETTING UP IDX ENVIRONMENT..."
            echo ""

            echo -e "${YELLOW}  [1/3] Cleaning workspace...${NC}"
            cd
            rm -rf myapp flutter
            sleep 0.5

            echo -e "${YELLOW}  [2/3] Creating directory structure...${NC}"
            echo -e "${GREEN}   [1]${WHITE} vm/.idx"
            echo -e "${GREEN}   [2]${WHITE} vps123/.idx"
            echo -e "${GREEN}   [3]${WHITE} Custom path"
            echo -ne "${CYAN}   Choose [1-3]: ${NC}"
            read IDX_CHOICE

            case "$IDX_CHOICE" in
                1) IDX_PATH="$HOME/vm/.idx" ;;
                2) IDX_PATH="$HOME/vps123/.idx" ;;
                3)
                    echo -ne "${CYAN}   Enter custom path (example: mydir/.idx): ${NC}"
                    read CUSTOM_PATH
                    IDX_PATH="$HOME/$CUSTOM_PATH"
                    ;;
                *)
                    IDX_PATH="$HOME/vm/.idx"
                    ;;
            esac

            mkdir -p "$IDX_PATH"
            cd "$IDX_PATH"
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
            echo -e "\n${GREEN}  SUCCESS: IDX Config created at ${IDX_PATH}${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        3)
            draw_header
            status_msg "LAUNCHING IDX VPS SCRIPT..."
            loading_bar
            bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vm-idx.sh)
            read -n 1 -s -r -p "Press any key..."
            ;;

        4)
            draw_header
            status_msg "INSTALLING AUTO-START SCRIPT..." "${CYAN}"
            echo ""

            # 1. Membuat file vm-autostart.sh
            echo -e "${YELLOW}  [1/2] Creating vm-autostart.sh...${NC}"
            cat <<'EOF' > "$HOME/vm-autostart.sh"
#!/bin/bash

# Pastikan vm.conf ada, kalau tidak buat dummy atau exit
if [ ! -f "$HOME/vm.conf" ]; then
    echo "[ERROR] $HOME/vm.conf not found. Please setup VM first." > "$HOME/vm.log"
    exit 1
fi

source "$HOME/vm.conf"
LOG="$HOME/vm.log"

while true; do
  if pgrep -f "qemu-system.*$IMG" >/dev/null; then
    sleep 5
    continue
  fi

  echo "[INFO] $(date) VM $VM_NAME starting..." >> "$LOG"

  qemu-system-x86_64 \
    -machine accel=tcg,thread=multi \
    -cpu max \
    -m "$RAM" \
    -smp "$CPU" \
    -drive file="$IMG",format=qcow2,if=virtio \
    -drive file="$SEED",format=raw,if=virtio \
    -netdev user,id=n0,hostfwd=tcp::"$SSH_PORT"-:22 \
    -device virtio-net-pci,netdev=n0 \
    -nographic \
    >> "$LOG" 2>&1

  echo "[WARN] $(date) VM stopped, restarting..." >> "$LOG"
  sleep 3
done
EOF
            chmod +x "$HOME/vm-autostart.sh"
            sleep 1

            # 2. Menambahkan trigger ke .bashrc
            echo -e "${YELLOW}  [2/2] Registering to .bashrc...${NC}"
            
            # Cek apakah sudah terpasang sebelumnya biar ga double
            if grep -q "IDX VM AUTOSTART" "$HOME/.bashrc"; then
                echo -e "${RED}  Already installed in .bashrc! Skipping.${NC}"
            else
                cat <<'EOF' >> "$HOME/.bashrc"

# ==== IDX VM AUTOSTART ====
VM_FLAG="$HOME/.vm_started"

if [ ! -f "$VM_FLAG" ]; then
  touch "$VM_FLAG"
  nohup "$HOME/vm-autostart.sh" >/dev/null 2>&1 &
fi
EOF
                echo -e "${GREEN}  Autostart Added to .bashrc!${NC}"
            fi

            loading_bar
            echo -e "\n${GREEN}  SUCCESS: Auto-Start System Installed!${NC}"
            echo -e "${WHITE}  Script will run automatically next time you restart IDX/Terminal.${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        5)
            clear
            echo -e "${RED}EXITING...${NC}"
            exit 0
            ;;
    esac
done
