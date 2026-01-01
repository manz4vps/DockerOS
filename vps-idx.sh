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
set -euo pipefail

# =============================
# VM Starter (Start Only)
# =============================

# --- COLOR DEFINITIONS ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize VM Directory
VM_DIR="${VM_DIR:-$HOME/vms}"

# Function to display header
display_header() {
    clear
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN}         VM STARTER MODUL                               ${BLUE}║${NC}"
    echo -e "${BLUE}║${YELLOW}         P O W E R E D   B Y   M A N Z               ${BLUE}║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    echo
}

# Function to display colored output
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

# Check dependencies
check_dependencies() {
    if ! command -v qemu-system-x86_64 &> /dev/null; then
        print_status "ERROR" "🔧 QEMU not found. Please install qemu-system-x86_64"
        exit 1
    fi
}

# Get list of existing VMs
get_vm_list() {
    if [ -d "$VM_DIR" ]; then
        find "$VM_DIR" -name "*.conf" -exec basename {} .conf \; 2>/dev/null | sort
    fi
}

# Load VM Config
load_vm_config() {
    local vm_name=$1
    local config_file="$VM_DIR/$vm_name.conf"
    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE IMG_FILE SEED_FILE SSH_PORT USERNAME PASSWORD MEMORY CPUS DISK_SIZE GUI_MODE PORT_FORWARDS
        source "$config_file"
        return 0
    else
        print_status "ERROR" "📂 Configuration for VM '$vm_name' not found"
        return 1
    fi
}

# Check if VM is running
is_vm_running() {
    local vm_name=$1
    # Check by image file path in process list
    if load_vm_config "$vm_name" 2>/dev/null; then
        if pgrep -f "qemu-system.*$IMG_FILE" >/dev/null; then
            return 0
        fi
    fi
    return 1
}

# Check image lock
check_image_lock() {
    local img_file=$1
    local vm_name=$2
    if lsof "$img_file" 2>/dev/null | grep -q qemu-system; then
        return 1
    fi
    return 0
}

# Stop VM (Needed if user wants to restart)
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
    fi
}

# === MAIN START FUNCTION ===
start_vm() {
    local vm_name=$1
    
    if load_vm_config "$vm_name"; then
        # Check if VM is already running
        if is_vm_running "$vm_name"; then
            print_status "WARN" "⚠️  VM '$vm_name' is already running"
            read -p "$(print_status "INPUT" "🔄 Stop and restart? (y/N): ")" restart_choice
            if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
                stop_vm "$vm_name"
                sleep 2
            else
                return 1
            fi
        fi
        
        # Check lock
        if ! check_image_lock "$IMG_FILE" "$vm_name"; then
             print_status "WARN" "🔒 Image file seems locked by another process."
             read -p "$(print_status "INPUT" "Force remove lock and start? (y/N): ")" force_unlock
             if [[ "$force_unlock" =~ ^[Yy]$ ]]; then
                rm -f "${IMG_FILE}.lock"
             else
                return 1
             fi
        fi

        print_status "INFO" "🚀 Starting VM: $vm_name"
        print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
        print_status "INFO" "🔑 Password: $PASSWORD"
        
        # Validation checks
        if [[ ! -f "$IMG_FILE" ]]; then
            print_status "ERROR" "❌ VM image file not found: $IMG_FILE"
            return 1
        fi
        if [[ ! -f "$SEED_FILE" ]]; then
            print_status "ERROR" "❌ Seed file missing. Cannot recreate in this simplified script."
            return 1
        fi
        
        # QEMU Command
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

        # Port Forwards
        if [[ -n "${PORT_FORWARDS:-}" ]]; then
            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"
            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"
                qemu_cmd+=(-device "virtio-net-pci,netdev=n${#qemu_cmd[@]}")
                qemu_cmd+=(-netdev "user,id=n${#qemu_cmd[@]},hostfwd=tcp::$host_port-:$guest_port")
            done
        fi

        # Display Mode
        if [[ "${GUI_MODE:-false}" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk,gl=on)
            print_status "INFO" "🖥️  Starting in GUI mode..."
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
            print_status "INFO" "📟 Starting in console mode..."
            print_status "INFO" "🛑 Press Ctrl+A then X to exit QEMU console"
        fi

        echo "📊 Configuration: ${MEMORY}MB RAM, ${CPUS} CPUs, ${DISK_SIZE} disk"
        
        # Execute
        if ! "${qemu_cmd[@]}"; then
            print_status "ERROR" "❌ Failed to start VM."
            rm -f "${IMG_FILE}.lock" 2>/dev/null
            return 1
        fi
        
        print_status "INFO" "🛑 VM $vm_name has been shut down"
    fi
}

# === MAIN LOGIC ===
check_dependencies
display_header

# Get VMs
vms=($(get_vm_list))
vm_count=${#vms[@]}

if [ $vm_count -eq 0 ]; then
    print_status "WARN" "No VMs found in $VM_DIR"
    exit 0
fi

print_status "INFO" "📂 Found $vm_count existing VM(s):"
for i in "${!vms[@]}"; do
    status="💤"
    if is_vm_running "${vms[$i]}"; then
        status="🚀 (Running)"
    fi
    printf "  %2d) %s %s\n" $((i+1)) "${vms[$i]}" "$status"
done
echo

read -p "$(print_status "INPUT" "🚀 Enter VM number to start: ")" vm_num

if [[ "$vm_num" =~ ^[0-9]+$ ]] && [ "$vm_num" -ge 1 ] && [ "$vm_num" -le $vm_count ]; then
    start_vm "${vms[$((vm_num-1))]}"
else
    print_status "ERROR" "❌ Invalid selection"
fi
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
