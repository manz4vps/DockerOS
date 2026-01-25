#!/bin/bash

# ==============================================================================
# MANZ XD - ULTIMATE CONSOLE (V2 - Modified Fast)
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
    echo -e "${BLUE}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}  ║${CYAN}       MANZ XD - ULTIMATE CONSOLE     ${BLUE}║${NC}"
    echo -e "${BLUE}  ╚══════════════════════════════════════╝${NC}"
}

draw_header() {
    clear
    draw_logo
    echo -e "\n${GREY}      SYSTEM TIME: $(date '+%H:%M:%S') | USER: $(whoami)${NC}"
}

status_msg() {
    local title="$1"
    local color="$2"
    echo -e "${color}>>> ${title}${NC}"
}

# --- MAIN LOGIC ---

while true; do
    draw_header

    echo -e "${CYAN}  [ MENU SELECTION ]${NC}"
    echo -e "${BLUE}  ╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}  ║ ${GREEN}1)${WHITE}🚀 GitHub VPS Maker (Docker)                 ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}2)${WHITE}🚀 Codesandbox VPS Maker (KVM)               ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}3)${WHITE}🔧 IDX Tool Setup (Auto vm/.idx)             ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}4)${WHITE}⚡ IDX VPS Maker (Auto Script)               ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}5)${WHITE}🤖 Setup Auto-Start VM (Pasang Otomatis)     ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}0)${WHITE}❌ Exit Console                              ${BLUE}║${NC}"
    echo -e "${BLUE}  ╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -ne "${YELLOW}  Select Option [0-4]: ${NC}"
    read selection

    case $selection in
        1)
           draw_header
           clear
           status_msg "🚀 Menjalankan VPS GitHub Installer..."
           bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/vps-github.sh)
           read -n 1 -s -r -p "Press any key..."
           ;;
           
        2)
           draw_header
           clear
           status_msg "🚀 Menjalankan VPS codesandbox..."
           bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/codesandbox-backed.sh)
           read -n 1 -s -r -p "Press any key..."
           ;;
           
        3)
            draw_header
            status_msg "SETTING UP IDX ENVIRONMENT..."
            echo ""
            echo -e "${YELLOW}  [1/3] Cleaning workspace...${NC}"
            cd
            rm -rf myapp
            rm -rf myapp flutter
            rm -rf /home/user/.gradle
            rm -rf /home/user/.pub-cache
            sudo umount -l /home/user/.emu
            rm -rf /home/user/.emu
            sleep 0.5
            echo -e "${YELLOW}  [2/3] Setting up directory...${NC}"
            IDX_PATH="$HOME/vm/.idx"
            echo -e "${GREEN}   Target: $IDX_PATH${NC}"
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
            echo -e "\n${GREEN}  SUCCESS: IDX Config created at ${IDX_PATH}${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        4)
            draw_header
            status_msg "LAUNCHING IDX VPS SCRIPT..."
            bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/vm-idx.sh)
            read -n 1 -s -r -p "Press any key..."
            ;;

        5)
            draw_header
            status_msg "INSTALLING AUTO-START SCRIPT..." "${CYAN}"
            echo ""

            # 1. Membuat file vm-autostart.sh
            echo -e "${YELLOW}  [1/2] Creating vm-autostart.sh...${NC}"
            cat <<'EOF' > "$HOME/vm-autostart.sh"
#!/bin/bash
set -euo pipefail

# =============================
# Auto VM Starter (ManzXD)
# =============================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

VM_DIR="${VM_DIR:-$HOME/vms}"

print_status() {
    local type=$1
    local message=$2
    case $type in
        "INFO") echo -e "\033[1;34m📋 [INFO]\033[0m $message" ;;
        "WARN") echo -e "\033[1;33m⚠️  [WARN]\033[0m $message" ;;
        "ERROR") echo -e "\033[1;31m❌ [ERROR]\033[0m $message" ;;
        "SUCCESS") echo -e "\033[1;32m✅ [SUCCESS]\033[0m $message" ;;
        "INPUT") echo -e "\033[1;36m🎯 [INPUT]\033[0m $message" ;;
        *) echo "[$type] $message" ;;
    esac
}

check_dependencies() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        print_status "ERROR" "🔧 QEMU not found."
        exit 1
    fi
}

get_vm_list() {
    if [ -d "$VM_DIR" ]; then
        find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
    fi
}

load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE IMG_FILE SEED_FILE SSH_PORT USERNAME PASSWORD MEMORY CPUS DISK_SIZE GUI_MODE PORT_FORWARDS
        source "$config_file"
        return 0
    else
        return 1
    fi
}

is_vm_running() {
    local vm_name=$1
    if load_vm_config "$vm_name" 2>/dev/null; then
        if pgrep -f "qemu-system.*$IMG_FILE" >/dev/null; then
            return 0
        fi
    fi
    return 1
}

check_image_lock() {
    local img_file=$1
    if lsof "$img_file" 2>/dev/null | grep -q qemu-system; then
        return 1
    fi
    return 0
}

stop_vm() {
    local vm_name=$1
    if load_vm_config "$vm_name"; then
        print_status "INFO" "🛑 Stopping VM: $vm_name"
        pkill -f "qemu-system.*$IMG_FILE"
        sleep 2
        if is_vm_running "$vm_name"; then
            pkill -9 -f "qemu-system.*$IMG_FILE"
        fi
        rm -f "${IMG_FILE}.lock" 2>/dev/null
        print_status "SUCCESS" "VM Stopped."
    fi
}

start_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        # LOGIC BARU: Jika VM sudah jalan, tanya User
        if is_vm_running "$vm_name"; then
            echo ""
            print_status "WARN" "⚠️  VM '$vm_name' is ALREADY RUNNING."
            echo -ne "\033[1;36m🎯 [INPUT] 🔄 Do you want to RESTART it? (y/N): \033[0m"
            read -r restart_choice
            
            if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
                echo ""
                stop_vm "$vm_name"
                sleep 2
            else
                echo -e "\033[1;32m✅ Keeping VM running. Exiting.\033[0m"
                exit 0
            fi
        fi
        
        if ! check_image_lock "$IMG_FILE" "$vm_name"; then
             rm -f "${IMG_FILE}.lock"
        fi

        print_status "INFO" "🚀 Starting VM: $vm_name"
        print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
        
        local qemu_cmd=(
            qemu-system-x86_64
            -enable-kvm
            -m "$MEMORY"
            -smp "$CPUS"
            -cpu host
            -drive "file=$IMG_FILE,format=qcow2,if=virtio"
            -drive "file=$SEED_FILE,format=raw,if=virtio"
            -boot order=c
            -device virtio-net-pci,netdev=n0
            -netdev "user,id=n0,hostfwd=tcp::$SSH_PORT-:22"
            -device virtio-balloon-pci
            -object rng-random,filename=/dev/urandom,id=rng0
            -device virtio-rng-pci,rng=rng0
        )

        if [[ -n "${PORT_FORWARDS:-}" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-device "virtio-net-pci,netdev=n${#qemu_cmd[@]}")
                qemu_cmd+=(-netdev "user,id=n${#qemu_cmd[@]},hostfwd=tcp::$host_port-:$guest_port")
            done
        fi

        if [[ "${GUI_MODE:-false}" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk,gl=on)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
            print_status "INFO" "📟 Starting in console mode..."
            print_status "INFO" "🛑 Press Ctrl+A then X to exit QEMU console"
        fi

        if ! "${qemu_cmd[@]}"; then
            print_status "ERROR" "❌ Failed to start VM."
            return 1
        fi
        
        print_status "INFO" "🛑 VM $vm_name has been shut down"
    fi
}

check_dependencies
vms=($(get_vm_list))
vm_count=${#vms[@]}

clear
if [ $vm_count -eq 0 ]; then
    print_status "ERROR" "❌ No VM Config found in $VM_DIR"
    exit 1
fi

TARGET_VM="${vms[0]}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${CYAN}         AUTO VM STARTER (MANZ XD)                      ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

print_status "INFO" "🔎 Found ${vm_count} VMs."
print_status "SUCCESS" "🎯 Target VM: $TARGET_VM"

start_vm "$TARGET_VM"
EOF
            chmod +x "$HOME/vm-autostart.sh"
            sleep 1

            # 2. Menambahkan trigger ke .bashrc (BAGIAN INI YANG PENTING)
            echo -e "${YELLOW}  [2/2] Registering to .bashrc...${NC}"
            
            if grep -q "IDX VM AUTOSTART" "$HOME/.bashrc"; then
                echo -e "${RED}  Already installed in .bashrc! Skipping.${NC}"
            else
                cat <<'EOF' >> "$HOME/.bashrc"

# ==========================================
# IDX VM AUTOSTART (MANZ XD)
# ==========================================
# Kita panggil scriptnya langsung, biarkan script
# yang mengecek status VM dan tanya user.
if [ -f "$HOME/vm-autostart.sh" ]; then
    (cd /home/user && bash ./vm-autostart.sh)
fi
EOF
                echo -e "${GREEN}  Autostart Added to .bashrc!${NC}"
            fi

            echo -e "\n${GREEN}  SUCCESS: Auto-Start System Installed!${NC}"
            echo -e "${WHITE}  Please restart your terminal to test.${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        0)
            clear
            echo -e "${RED}EXITING...${NC}"
            exit 0
            ;;
    esac
done
