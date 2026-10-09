#!/usr/bin/env bash

# ==============================================================================
# MANZ XD - ULTIMATE CONSOLE
# PREMIUM CLI UI V3.0
# ==============================================================================

# --- COLOR PALETTE ---
if [[ -t 1 ]]; then
    CYAN='\033[1;36m'
    PURPLE='\033[1;35m'
    BLUE='\033[1;34m'
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    WHITE='\033[1;37m'
    GREY='\033[0;90m'
    NC='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'
else
    CYAN='' PURPLE='' BLUE='' GREEN=''
    RED='' YELLOW='' WHITE='' GREY=''
    NC='' BOLD='' DIM=''
fi

APP_NAME="MANZ XD ULTIMATE CONSOLE"
APP_VERSION="3.0"

# --- SYSTEM FUNCTIONS ---

draw_logo() {
    echo
    echo -e "${CYAN}  ╭────────────────────────────────────────────────────────────╮${NC}"
    echo -e "${CYAN}  │${PURPLE}${BOLD}                  M A N Z   X D                              ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}  │${WHITE}${BOLD}                ULTIMATE CONSOLE                             ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}  │${GREY}                 PREMIUM CLI EDITION                        ${NC}${CYAN}│${NC}"
    echo -e "${CYAN}  ╰────────────────────────────────────────────────────────────╯${NC}"
}

draw_header() {
    clear 2>/dev/null || printf '\033[2J\033[H'

    draw_logo

    echo
    printf '  %bSYSTEM%b  %s\n' "${CYAN}${BOLD}" "${NC}" "ONLINE"
    printf '  %bUSER%b    %s\n' "${CYAN}${BOLD}" "${NC}" "$(whoami 2>/dev/null || echo unknown)"
    printf '  %bTIME%b    %s\n' "${CYAN}${BOLD}" "${NC}" "$(date '+%d-%m-%Y  %H:%M:%S')"
    printf '  %bVERSION%b %s\n' "${CYAN}${BOLD}" "${NC}" "$APP_VERSION"

    echo
    echo -e "${BLUE}  ────────────────────────────────────────────────────────────${NC}"
}

status_msg() {
    local title="$1"
    local color="${2:-$CYAN}"

    echo
    echo -e "  ${color}${BOLD}◆ ${title}${NC}"
    echo -e "${BLUE}  ────────────────────────────────────────────────────────────${NC}"
    echo
}

draw_section() {
    echo
    echo -e "  ${PURPLE}${BOLD}▸ $1${NC}"
    echo -e "  ${BLUE}────────────────────────────────────────────────────────────${NC}"
}

draw_item() {
    printf '  %b[%02d]%b %s\n' "${GREEN}${BOLD}" "$1" "${NC}" "$2"
}

draw_footer() {
    echo
    echo -e "${BLUE}  ────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${GREY}MANZXD ${NC}${PURPLE}•${NC}${GREY} ULTIMATE CONSOLE${NC}"
}

pause_screen() {
    echo
    read -r -n 1 -s -p "  ${CYAN}Tekan tombol apa saja untuk kembali...${NC}"
    echo
}

# --- MAIN LOGIC ---

while true; do
    draw_header

    draw_section "VPS & VIRTUAL MACHINE"

    draw_item 1 "GitHub VPS Maker (Docker)"
    draw_item 2 "VPS Maker (Non-KVM)"
    draw_item 3 "IDX Tool Setup (Auto vm/.idx)"
    draw_item 4 "IDX VPS Maker (Auto Script)"

    draw_section "AUTOMATION & ENVIRONMENT"

    draw_item 5 "Setup Auto-Start VM (Deteksi KVM)"
    draw_item 6 "Freeroot Auto Installer"
    draw_item 7 "Setup Replit Auto Start"
    draw_item 8 "Install Panel on Replit"
    draw_item 9 "Setup GitHub Codespace"

    draw_section "SYSTEM"

    draw_item 0 "Exit Console"

    draw_footer

    echo
    printf '  %bMANZXD%b %b»%b Select Option [0-9]: ' \
        "${CYAN}${BOLD}" "${NC}" "${PURPLE}" "${NC}"

    read -r selection
    selection="${selection//[[:space:]]/}"

    case "$selection" in

        1)
            draw_header
            status_msg "MENJALANKAN GITHUB VPS INSTALLER" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/vps-github.sh)

            pause_screen
            ;;

        2)
            draw_header
            status_msg "MENJALANKAN VPS MAKER NON-KVM" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/vps-any-kvm1.sh)

            pause_screen
            ;;

        3)
            draw_header
            status_msg "IDX ENVIRONMENT SETUP" "$CYAN"

            echo -e "${YELLOW}  [1/3] Membersihkan workspace...${NC}"

            echo -e "${GREY}  -> Menghentikan proses terkait...${NC}"
            pkill -f gradle 2>/dev/null
            pkill -f flutter 2>/dev/null
            pkill -f dart 2>/dev/null
            pkill -f qemu 2>/dev/null
            pkill -f androidsdkroot 2>/dev/null

            echo -e "${GREY}  -> Menunggu proses berhenti...${NC}"
            sleep 3

            # PERHATIAN:
            # Bagian ini menghapus data/cache pada path berikut.
            # Pastikan data penting telah dicadangkan.
            cd /home/user || {
                echo -e "${RED}Gagal masuk ke /home/user${NC}"
                pause_screen
                continue
            }

            echo -e "${GREY}  -> Menghapus cache dan folder workspace...${NC}"

            rm -rf /home/user/.gradle
            rm -rf /home/user/.pub-cache
            rm -rf /home/user/myapp
            rm -rf /home/user/flutter

            echo -e "${GREY}  -> Unmount environment...${NC}"

            sudo umount -l /home/user/.emu 2>/dev/null
            sudo umount -l /home/user/.androidsdkroot 2>/dev/null

            rm -rf /home/user/.emu 2>/dev/null
            rm -rf /home/user/.androidsdkroot 2>/dev/null

            echo -e "${GREEN}  ✓ Workspace dibersihkan.${NC}"
            sleep 1

            echo -e "${YELLOW}  [2/3] Menyiapkan direktori...${NC}"

            IDX_PATH="/home/user/vm/.idx"

            echo -e "${GREEN}  Target: ${IDX_PATH}${NC}"

            mkdir -p "$IDX_PATH" || {
                echo -e "${RED}Gagal membuat direktori IDX.${NC}"
                pause_screen
                continue
            }

            cd "$IDX_PATH" || {
                echo -e "${RED}Gagal masuk ke direktori IDX.${NC}"
                pause_screen
                continue
            }

            sleep 0.5

            echo -e "${YELLOW}  [3/3] Membuat konfigurasi dev.nix...${NC}"

            cat <<'EOF' > dev.nix
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

            echo
            echo -e "${GREEN}${BOLD}  ✓ IDX CONFIG BERHASIL DIBUAT${NC}"
            echo -e "  ${GREY}Lokasi: ${IDX_PATH}/dev.nix${NC}"

            pause_screen
            ;;

        4)
            draw_header
            status_msg "MENJALANKAN IDX VPS SCRIPT" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/vm-idx.sh)

            pause_screen
            ;;

        5)
            draw_header
            status_msg "MEMASANG VM AUTO-START" "$CYAN"

            echo -e "${YELLOW}  [1/2] Membuat vm-autostart.sh...${NC}"

            cat <<'EOF' > "$HOME/vm-autostart.sh"
#!/usr/bin/env bash
set -euo pipefail

# =============================
# Auto VM Starter (ManzXD)
# =============================

RED='\033[0;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
NC='\033[0m'

VM_DIR="${VM_DIR:-$HOME/vms}"

print_status() {
    local type="$1"
    local message="$2"

    case "$type" in
        INFO)    echo -e "${BLUE}[INFO]${NC} $message" ;;
        WARN)    echo -e "${YELLOW}[WARN]${NC} $message" ;;
        ERROR)   echo -e "${RED}[ERROR]${NC} $message" ;;
        SUCCESS) echo -e "${GREEN}[SUCCESS]${NC} $message" ;;
        INPUT)   echo -e "${CYAN}[INPUT]${NC} $message" ;;
        *)       echo "[$type] $message" ;;
    esac
}

check_dependencies() {
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        print_status ERROR "QEMU tidak ditemukan."
        exit 1
    fi
}

get_vm_list() {
    if [[ -d "$VM_DIR" ]]; then
        find "$VM_DIR" -name "*.conf" \
            -exec basename {} .conf \; 2>/dev/null | sort
    fi
}

load_vm_config() {
    local vm_name="$1"
    local config_file="$VM_DIR/$vm_name.conf"

    if [[ -f "$config_file" ]]; then
        unset VM_NAME OS_TYPE IMG_FILE SEED_FILE SSH_PORT USERNAME
        unset PASSWORD MEMORY CPUS DISK_SIZE GUI_MODE PORT_FORWARDS

        source "$config_file"
        return 0
    fi

    return 1
}

is_vm_running() {
    local vm_name="$1"

    if load_vm_config "$vm_name" 2>/dev/null; then
        if pgrep -f "qemu-system.*$IMG_FILE" >/dev/null; then
            return 0
        fi
    fi

    return 1
}

check_image_lock() {
    local img_file="$1"

    if lsof "$img_file" 2>/dev/null | grep -q qemu-system; then
        return 1
    fi

    return 0
}

stop_vm() {
    local vm_name="$1"

    if load_vm_config "$vm_name"; then
        print_status INFO "Menghentikan VM: $vm_name"

        pkill -f "qemu-system.*$IMG_FILE" || true
        sleep 2

        if is_vm_running "$vm_name"; then
            pkill -9 -f "qemu-system.*$IMG_FILE" || true
        fi

        rm -f "${IMG_FILE}.lock" 2>/dev/null || true

        print_status SUCCESS "VM dihentikan."
    fi
}

start_vm() {
    local vm_name="$1"

    if load_vm_config "$vm_name"; then
        if is_vm_running "$vm_name"; then
            echo
            print_status WARN "VM '$vm_name' sudah berjalan."
            read -r -p "Restart VM? (y/N): " restart_choice

            if [[ "$restart_choice" =~ ^[Yy]$ ]]; then
                stop_vm "$vm_name"
                sleep 2
            else
                print_status INFO "VM tetap berjalan."
                exit 0
            fi
        fi

        if ! check_image_lock "$IMG_FILE"; then
            rm -f "${IMG_FILE}.lock"
        fi

        print_status INFO "Memulai VM: $vm_name"
        print_status INFO "SSH: ssh -p $SSH_PORT $USERNAME@localhost"

        local -a qemu_cmd=(qemu-system-x86_64)

        if [[ -e /dev/kvm && -r /dev/kvm && -w /dev/kvm ]]; then
            print_status SUCCESS "KVM tersedia; menggunakan akselerasi hardware."
            qemu_cmd+=(-enable-kvm -cpu host)
        else
            print_status WARN "KVM tidak tersedia; menggunakan emulasi software."
            qemu_cmd+=(-cpu max)
        fi

        qemu_cmd+=(
            -m "$MEMORY"
            -smp "$CPUS"
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
            local index=1
            local forward host_port guest_port

            IFS=',' read -ra forwards <<< "$PORT_FORWARDS"

            for forward in "${forwards[@]}"; do
                IFS=':' read -r host_port guest_port <<< "$forward"

                qemu_cmd+=(
                    -device "virtio-net-pci,netdev=n${index}"
                    -netdev "user,id=n${index},hostfwd=tcp::$host_port-:$guest_port"
                )

                ((index += 1))
            done
        fi

        if [[ "${GUI_MODE:-false}" == true ]]; then
            qemu_cmd+=(-vga virtio -display gtk,gl=on)
        else
            qemu_cmd+=(-nographic -serial mon:stdio)
            print_status INFO "Mode console aktif."
            print_status INFO "Tekan Ctrl+A lalu X untuk keluar dari console QEMU."
        fi

        if ! "${qemu_cmd[@]}"; then
            print_status ERROR "Gagal menjalankan VM."
            return 1
        fi

        print_status INFO "VM $vm_name telah dimatikan."
    fi
}

check_dependencies

mapfile -t vms < <(get_vm_list)
vm_count=${#vms[@]}

clear

if (( vm_count == 0 )); then
    print_status ERROR "Tidak ada konfigurasi VM di $VM_DIR"
    exit 1
fi

TARGET_VM="${vms[0]}"

echo -e "${BLUE}╭──────────────────────────────────────────────────────────╮${NC}"
echo -e "${BLUE}│${CYAN}               AUTO VM STARTER • MANZ XD                 ${BLUE}│${NC}"
echo -e "${BLUE}╰──────────────────────────────────────────────────────────╯${NC}"

print_status INFO "Jumlah VM ditemukan: $vm_count"
print_status SUCCESS "Target VM: $TARGET_VM"

start_vm "$TARGET_VM"
EOF

            chmod +x "$HOME/vm-autostart.sh"

            sleep 1

            echo -e "${YELLOW}  [2/2] Memeriksa konfigurasi .bashrc...${NC}"

            touch "$HOME/.bashrc"

            if grep -q "IDX VM AUTOSTART" "$HOME/.bashrc"; then
                echo -e "${YELLOW}  Konfigurasi autostart sudah ada.${NC}"
            else
                cat <<'EOF' >> "$HOME/.bashrc"

# ==========================================
# IDX VM AUTOSTART (MANZ XD)
# ==========================================
if [ -f "$HOME/vm-autostart.sh" ]; then
    (cd "$HOME" && bash ./vm-autostart.sh)
fi
EOF
                echo -e "${GREEN}  ✓ Autostart ditambahkan ke .bashrc.${NC}"
            fi

            echo
            echo -e "${GREEN}${BOLD}  ✓ VM AUTO-START SELESAI DIPASANG${NC}"
            echo -e "${GREY}  File: $HOME/vm-autostart.sh${NC}"
            echo -e "${YELLOW}  Autostart akan berjalan ketika shell membaca .bashrc.${NC}"

            pause_screen
            ;;

        6)
            draw_header
            status_msg "MENJALANKAN FREEROOT AUTO INSTALLER" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/freeroot.sh)

            pause_screen
            ;;

        7)
            draw_header
            status_msg "MENYIAPKAN REPLIT AUTO-START" "$CYAN"

            REPLIT_CONFIG="/home/runner/workspace/.config"

            echo -e "${YELLOW}  [1/2] Membuat direktori konfigurasi...${NC}"

            mkdir -p "$REPLIT_CONFIG" || {
                echo -e "${RED}Gagal membuat direktori konfigurasi.${NC}"
                pause_screen
                continue
            }

            echo -e "${YELLOW}  [2/2] Membuat file bashrc...${NC}"

            cat <<'EOF' > "$REPLIT_CONFIG/bashrc"
# ====================================================================
# AUTO RUN FREEROOT OS BY MANZ4VPS
# ====================================================================
bash <(curl -fsSL https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/freeroot.sh)
EOF

            echo
            echo -e "${GREEN}${BOLD}  ✓ REPLIT CONFIG BERHASIL DIBUAT${NC}"
            echo -e "  ${GREY}Lokasi: ${REPLIT_CONFIG}/bashrc${NC}"

            pause_screen
            ;;

        8)
            draw_header
            status_msg "MENJALANKAN SETUP REPLIT" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/setup-repl.sh)

            pause_screen
            ;;

        9)
            draw_header
            status_msg "MENJALANKAN GITHUB CODESPACE SETUP" "$GREEN"

            bash <(curl -fsSL \
                https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/Github.sh)

            pause_screen
            ;;

        0)
            clear
            echo
            echo -e "${PURPLE}  ╭────────────────────────────────────────────╮${NC}"
            echo -e "${PURPLE}  │${GREEN}${BOLD}       THANK YOU FOR USING MANZ XD          ${NC}${PURPLE}│${NC}"
            echo -e "${PURPLE}  ╰────────────────────────────────────────────╯${NC}"
            echo
            exit 0
            ;;

        "")
            ;;

        *)
            echo
            echo -e "  ${RED}${BOLD}✗ Pilihan tidak valid.${NC}"
            sleep 1
            ;;
    esac
done
