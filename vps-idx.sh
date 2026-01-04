#!/bin/bash

# ==============================================================================
# MANZ XD - ULTIMATE CONSOLE (V5 - Clear Screen Error)
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
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN}       MANZ XD - ULTIMATE CONSOLE     ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
}

draw_header() {
    clear
    draw_logo
    echo -e "\n${GREY}      SYSTEM TIME: $(date '+%H:%M:%S') | USER: $(whoami)${NC}"
}

status_msg() {
    echo -e "${2}>>> ${1}${NC}"
}

# --- MAIN LOGIC ---

while true; do
    draw_header

    echo -e "${CYAN}  [ MENU SELECTION ]${NC}"
    echo -e "${BLUE}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[1]${WHITE} 🚀 GitHub VPS Maker (Docker)                 ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[2]${WHITE} 🔧 IDX Tool Setup (Auto vm/.idx)             ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[3]${WHITE} ⚡ IDX VPS Maker (Auto Script)               ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[4]${WHITE} 🤖 Setup Auto-Start VM (Pasang Otomatis)     ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[0]${WHITE} ❌ Exit Console                               ${BLUE}║${NC}"
    echo -e "${BLUE}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Select Option [0-4]: ${NC}"
    read selection

    case $selection in
        1)
            draw_header
            status_msg "INITIALIZING GITHUB VPS..." "$CYAN"
            echo ""
            RAM=15000; CPU=4; DISK=100G; IMG="hopingboyz/debain12"
            mkdir -p "$PWD/vmdata"
            docker run -it --rm --name "manz_vps" --device /dev/kvm -v "$PWD/vmdata":/vmdata -e RAM="$RAM" -e CPU="$CPU" -e DISK_SIZE="$DISK" "$IMG"
            read -n 1 -s -r -p "Press any key..."
            ;;

        2)
            draw_header
            status_msg "SETTING UP IDX ENVIRONMENT..." "$CYAN"
            echo ""
            echo -e "${YELLOW}  [1/3] Cleaning workspace...${NC}"
            cd; rm -rf myapp flutter; sleep 0.5
            
            echo -e "${YELLOW}  [2/3] Setting up directory...${NC}"
            IDX_PATH="$HOME/vm/.idx"
            echo -e "${GREEN}   Target: $IDX_PATH${NC}"
            mkdir -p "$IDX_PATH"; cd "$IDX_PATH"; sleep 0.5

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
            echo -e "\n${GREEN}  SUCCESS: IDX Config created at ${IDX_PATH}${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        3)
            draw_header
            status_msg "LAUNCHING IDX VPS SCRIPT..." "$CYAN"
            bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vm-idx.sh)
            read -n 1 -s -r -p "Press any key..."
            ;;

        4)
            draw_header
            status_msg "INSTALLING AUTO-START SCRIPT..." "${CYAN}"
            echo ""

            # 1. Membuat file vm-autostart.sh dengan LOGIKA BARU
            echo -e "${YELLOW}  [1/2] Creating vm-autostart.sh...${NC}"
            cat <<'EOF' > "$HOME/vm-autostart.sh"
#!/bin/bash
set -euo pipefail

# =============================
# Auto VM Starter (ManzXD)
# =============================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'
VM_DIR="${VM_DIR:-$HOME/vms}"

check_dependencies() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        echo -e "${RED}[ERROR] QEMU not found.${NC}"; exit 1
    fi
}

get_vm_list() {
    if [ -d "$VM_DIR" ]; then
        find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
    fi
}

start_vm() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        if lsof "$IMG_FILE" 2>/dev/null | grep -q qemu-system; then return 0; fi
        rm -f "${IMG_FILE}.lock" 2>/dev/null

        echo -e "${GREEN}[START] Booting VM: $vm_name${NC}"
        echo -e "${BLUE}SSH: ssh -p $SSH_PORT $USERNAME@localhost${NC}"
        
        local qemu_cmd=(
            qemu-system-x86_64 -enable-kvm -m "$MEMORY" -smp "$CPUS" -cpu host
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
            -nographic -serial mon:stdio
        )
        if [[ -n "${PORT_FORWARDS:-}" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-device "virtio-net-pci,netdev=n${#qemu_cmd[@]}")
                qemu_cmd+=(-netdev "user,id=n${#qemu_cmd[@]},hostfwd=tcp::$host_port-:$guest_port")
            done
        fi
        "${qemu_cmd[@]}"
    fi
}

check_dependencies
vms=($(get_vm_list))

# --- BAGIAN LOGIKA ERROR (CLEAR SCREEN) ---
if [ ${#vms[@]} -eq 0 ]; then
    sleep 1     # Tunggu 1 detik biar kebaca bentar
    clear       # Hapus semua tulisan di terminal
    echo -e "${RED}[ERROR] ❌ Tidak ada konfigurasi VM ditemukan di $VM_DIR${NC}"
    exit 1
fi
# ------------------------------------------

TARGET_VM="${vms[0]}"
start_vm "$TARGET_VM"
EOF
            chmod +x "$HOME/vm-autostart.sh"
            sleep 1

            # 2. Register ke .bashrc
            echo -e "${YELLOW}  [2/2] Registering to .bashrc...${NC}"
            if grep -q "IDX VM AUTOSTART" "$HOME/.bashrc"; then
                echo -e "${RED}  Already installed in .bashrc! Skipping.${NC}"
            else
                cat <<'EOF' >> "$HOME/.bashrc"

# IDX VM AUTOSTART
if ! pgrep -f "qemu-system-x86_64" > /dev/null; then
    (cd $HOME && ./vm-autostart.sh)
fi
EOF
                echo -e "${GREEN}  Autostart Added!${NC}"
            fi

            echo -e "\n${GREEN}  SUCCESS: Auto-Start System Installed!${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        0)
            clear
            echo -e "${GREEN}EXITING...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid Option.${NC}"
            sleep 1
            ;;
    esac
done
