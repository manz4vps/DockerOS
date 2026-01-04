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
    # Logo Diperkecil & Simple
    echo -e "${BLUE}╔══════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${CYAN}       MANZ XD - ULTIMATE CONSOLE     ${BLUE}║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════╝${NC}"
}

draw_header() {
    clear
    draw_logo
    echo -e "\n${GREY}      SYSTEM TIME: $(date '+%H:%M:%S') | USER: $(whoami)${NC}"
}

# Loading bar dihapus, diganti echo biasa biar cepat
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
    echo -e "${BLUE}  ║ ${GREEN}[1]${WHITE} 🚀 GitHub VPS Maker (Docker)                 ${BLUE}║${NC}"
    echo -e "${BLUE}  ║ ${GREEN}[2]${WHITE} 🔧 IDX Tool Setup (Auto vm/.idx)             ${BLUE}║${NC}"
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

            # Loading bar dihapus

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

            echo -e "${YELLOW}  [2/3] Setting up directory...${NC}"
            
            # --- MODIFIKASI: LANGSUNG KE vm/.idx TANPA TANYA ---
            IDX_PATH="$HOME/vm/.idx"
            echo -e "${GREEN}   Target: $IDX_PATH${NC}"
            
            mkdir -p "$IDX_PATH"
            cd "$IDX_PATH"
            sleep 0.5

            echo -e "${YELLOW}  [3/3] Generating dev.nix config...${NC}"
            # ISI DEV.NIX TETAP SAMA SEPERTI SCIRPT V2 KAMU
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

            # Loading bar dihapus
            echo -e "\n${GREEN}  SUCCESS: IDX Config created at ${IDX_PATH}${NC}"
            read -n 1 -s -r -p "Press any key..."
            ;;

        3)
            draw_header
            status_msg "LAUNCHING IDX VPS SCRIPT..."
            # Loading bar dihapus
            bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vm-idx.sh)
            read -n 1 -s -r -p "Press any key..."
            ;;

        4)
            draw_header
            status_msg "INSTALLING AUTO-START SCRIPT..." "${CYAN}"
            echo ""

            # 1. Membuat file vm-autostart.sh (ISI TETAP SAMA V2)
            echo -e "${YELLOW}  [1/2] Creating vm-autostart.sh...${NC}"
            cat <<'EOF' > "$HOME/vm-autostart.sh"
#!/bin/bash
set -euo pipefail

# =============================
# Auto VM Starter (No Menu)
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
            # Opsi restart otomatis (uncomment baris di bawah jika ingin restart paksa tanpa tanya)
            # stop_vm "$vm_name"
            
            # Default: Tetap tanya agar aman
            read -p "$(print_status "INPUT" "🔄 Stop and restart? (y/N): ")" restart_choice
            if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
                stop_vm "$vm_name"
                sleep 2
            else
                exit 0
            fi
        fi
        
        # Check lock
        if ! check_image_lock "$IMG_FILE" "$vm_name"; then
             print_status "WARN" "🔒 Image file seems locked."
             rm -f "${IMG_FILE}.lock"
             print_status "INFO" "🔓 Lock removed."
        fi

        print_status "INFO" "🚀 Starting VM: $vm_name"
        print_status "INFO" "🔌 SSH: ssh -p $SSH_PORT $USERNAME@localhost"
        
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
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
            print_status "INFO" "📟 Starting in console mode..."
            print_status "INFO" "🛑 Press Ctrl+A then X to exit QEMU console"
        fi

        # Execute
        if ! "${qemu_cmd[@]}"; then
            print_status "ERROR" "❌ Failed to start VM."
            return 1
        fi
        
        print_status "INFO" "🛑 VM $vm_name has been shut down"
    fi
}

# === MAIN LOGIC (AUTO START) ===
check_dependencies

# Get list of VMs
vms=($(get_vm_list))
vm_count=${#vms[@]}

clear
if [ $vm_count -eq 0 ]; then
    print_status "ERROR" "❌ Tidak ada konfigurasi VM ditemukan di $VM_DIR"
    exit 1
fi

# AMBIL VM PERTAMA SECARA OTOMATIS
TARGET_VM="${vms[0]}"

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${CYAN}         AUTO VM STARTER (MANZ)                         ${BLUE}║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"

print_status "INFO" "🔎 Mendeteksi ${vm_count} VM..."
print_status "SUCCESS" "🎯 Memilih VM pertama: $TARGET_VM"

# Jalankan langsung
start_vm "$TARGET_VM"
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

# ==========================================
# AUTO START VM (FOREGROUND / LANGSUNG TAMPIL)
# ==========================================

# Cek dulu, kalau VM BELUM jalan, baru kita jalankan.
if ! pgrep -f "qemu-system-x86_64" > /dev/null; then
    
    echo "🚀 VM belum aktif. Menjalankan sekarang..."
    
    # Masuk ke folder user, lalu jalankan scriptnya secara langsung.
    # (cd ... ) memastikan kita pindah folder hanya untuk perintah ini saja.
    (cd /home/user && bash ./vm-autostart.sh)

else
    # Kalau sudah jalan, cuma kasih info aja.
    echo "✅ VM sudah berjalan."
fi
EOF
                echo -e "${GREEN}  Autostart Added to .bashrc!${NC}"
            fi

            # Loading bar dihapus
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
