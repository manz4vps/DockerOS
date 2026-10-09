#!/usr/bin/env bash

# ============================================================
#  MANZXD • DOCKER OS CONTROL CENTER
#  Premium CLI UI | Bash Edition
# ============================================================

APP_NAME="MANZXD DOCKER OS"
APP_VERSION="3.0"

# ---------- COLORS ----------
if [[ -t 1 ]]; then
    RESET='\033[0m'
    BOLD='\033[1m'
    DIM='\033[2m'
    CYAN='\033[1;36m'
    BLUE='\033[1;34m'
    PURPLE='\033[1;35m'
    GREEN='\033[1;32m'
    RED='\033[1;31m'
    YELLOW='\033[1;33m'
    WHITE='\033[1;37m'
    GREY='\033[0;90m'
else
    RESET='' BOLD='' DIM=''
    CYAN='' BLUE='' PURPLE=''
    GREEN='' RED='' YELLOW=''
    WHITE='' GREY=''
fi

# ---------- BASIC UTILITIES ----------
trap 'printf "\n%b\n" "${YELLOW}  [!] Console dihentikan.${RESET}"; exit 130' INT

pause() {
    echo
    read -r -n 1 -s -p "  Tekan tombol apa saja untuk kembali..."
    echo
}

line() {
    printf '%b\n' "${BLUE}  ────────────────────────────────────────────────────────${RESET}"
}

message() {
    local type="$1"
    shift

    case "$type" in
        OK)   printf '  %b\n' "${GREEN}[OK]${RESET} $*" ;;
        INFO) printf '  %b\n' "${CYAN}[INFO]${RESET} $*" ;;
        WARN) printf '  %b\n' "${YELLOW}[WARN]${RESET} $*" ;;
        ERR)  printf '  %b\n' "${RED}[ERROR]${RESET} $*" ;;
    esac
}

get_width() {
    local width
    width=$(tput cols 2>/dev/null || echo 80)

    if (( width > 100 )); then
        width=100
    elif (( width < 60 )); then
        width=60
    fi

    printf '%s' "$width"
}

draw_header() {
    clear 2>/dev/null || true

    printf '\n'
    printf '%b\n' "${CYAN}  ╭────────────────────────────────────────────────────────╮${RESET}"
    printf '%b\n' "${CYAN}  │${PURPLE}${BOLD}             MANZXD DOCKER OS CONTROL CENTER             ${RESET}${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  │${GREY}                  PREMIUM CLI EDITION                  ${RESET}${CYAN}│${RESET}"
    printf '%b\n' "${CYAN}  ╰────────────────────────────────────────────────────────╯${RESET}"

    printf '  %b\n' "${GREY}USER: $(whoami 2>/dev/null || echo unknown)  |  TIME: $(date '+%H:%M:%S')  |  VERSION: ${APP_VERSION}${RESET}"
    echo
}

draw_section() {
    printf '\n%b\n' "${PURPLE}${BOLD}  ◆ $1${RESET}"
    line
}

draw_item() {
    printf '  %b%-4s%b %s\n' "${GREEN}${BOLD}" "$1" "${RESET}" "$2"
}

prompt_choice() {
    printf '\n'
    printf '  %b' "${CYAN}${BOLD}  MANZXD ${RESET}${GREY}»${RESET} "
    read -r REPLY
    REPLY="${REPLY//[[:space:]]/}"
}

check_curl() {
    if command -v curl >/dev/null 2>&1; then
        return 0
    fi

    message WARN "curl belum tersedia."

    if [[ $EUID -ne 0 ]]; then
        message ERR "Jalankan sebagai root untuk memasang curl."
        return 1
    fi

    if [[ -f /etc/debian_version ]] && command -v apt-get >/dev/null 2>&1; then
        apt-get update -qq &&
            apt-get install -y curl -qq
    elif [[ -f /etc/redhat-release ]] && command -v yum >/dev/null 2>&1; then
        yum install -y curl
    else
        message ERR "Package manager tidak dikenali."
        return 1
    fi

    command -v curl >/dev/null 2>&1
}

run_script() {
    local url="$1"
    local file
    local status

    if [[ -z "$url" ]]; then
        message ERR "URL kosong."
        pause
        return 1
    fi

    if ! check_curl; then
        pause
        return 1
    fi

    draw_header
    draw_section "SCRIPT EXECUTION"
    message INFO "Mengunduh script dari sumber yang dikonfigurasi."
    printf '  %b%s%b\n' "$GREY" "$url" "$RESET"
    echo

    file=$(mktemp "${TMPDIR:-/tmp}/manzxd.XXXXXX") || {
        message ERR "Gagal membuat file sementara."
        pause
        return 1
    }

    if ! curl --fail --location --silent --show-error \
        --connect-timeout 15 \
        --max-time 180 \
        --output "$file" "$url"; then
        message ERR "Download gagal."
        rm -f "$file"
        pause
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        message ERR "File hasil download kosong."
        rm -f "$file"
        pause
        return 1
    fi

    # Script remote dijalankan tanpa sandbox.
    # Pastikan sumbernya dipercaya sebelum menjalankan.
    echo
    message INFO "Menjalankan script..."
    line

    bash "$file"
    status=$?

    rm -f "$file"

    echo
    if (( status == 0 )); then
        message OK "Proses selesai."
    else
        message ERR "Proses selesai dengan kode $status."
    fi

    pause
}

# ---------- SUBMENUS ----------
submenu() {
    local title="$1"
    shift

    local -a labels=()
    local -a urls=()
    local i choice

    while (( $# >= 2 )); do
        labels+=("$1")
        urls+=("$2")
        shift 2
    done

    while true; do
        draw_header
        draw_section "$title"

        for i in "${!labels[@]}"; do
            printf '  %b[%02d]%b %s\n' \
                "$GREEN" "$((i + 1))" "$RESET" "${labels[$i]}"
        done

        line
        draw_item "00" "Kembali ke menu utama"
        prompt_choice
        choice="$REPLY"

        case "$choice" in
            0|00)
                return
                ;;
            '' )
                ;;
            *[!0-9]*)
                message ERR "Pilihan tidak valid."
                sleep 1
                ;;
            *)
                if (( choice >= 1 && choice <= ${#labels[@]} )); then
                    run_script "${urls[$((choice - 1))]}"
                else
                    message ERR "Nomor menu tidak tersedia."
                    sleep 1
                fi
                ;;
        esac
    done
}

menu_wings() {
    submenu "WINGS INSTALLER" \
        "Wings Pterodactyl Original" \
        "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/Scrip/wings.sh" \
        "Wings Pterodactyl Update" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/wings-update.sh" \
        "Wings FeatherPanel" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/FeatherWings.sh"
}

menu_connection() {
    submenu "CONNECTION & TUNNEL" \
        "Install Localtonet" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-localtonet.sh" \
        "Install Tailscale" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-tailscale.sh" \
        "Tailscale Public IP" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/tailscale-port.sh" \
        "Install MineCube" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/minekub-ip.sh" \
        "Install Playit.gg" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/playitInstaller.sh" \
        "Playit 24/7" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/playit24-7"
}

menu_cloudflare() {
    submenu "CLOUDFLARE TOOLS" \
        "Cloudflare Raw Script" \
        "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/Scrip/cloudflare.sh" \
        "Cloudflared Tunnel Token" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/token-cloudflare.sh"
}

# ---------- MAIN MENU ----------
main_menu() {
    local choice

    while true; do
        draw_header

        draw_section "INSTALLATION"
        draw_item "01" "Panel Pterodactyl"
        draw_item "02" "Wings Installer                  [SUBMENU]"
        draw_item "03" "SSH Connect"
        draw_item "04" "Connection & Tunnel Tools        [SUBMENU]"
        draw_item "05" "Blueprint Framework"
        draw_item "06" "Cloudflare Tools                 [SUBMENU]"

        draw_section "CUSTOMIZATION & ADDONS"
        draw_item "07" "Pasang Tema"
        draw_item "08" "Install Addon"
        draw_item "09" "Install SSHX"
        draw_item "10" "Install CtrlPanel"
        draw_item "11" "Install Code-Server"

        draw_section "SYSTEM"
        draw_item "00" "Keluar dari console"

        prompt_choice
        choice="$REPLY"

        case "$choice" in
            1|01)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/panel.sh"
                ;;
            2|02)
                menu_wings
                ;;
            3|03)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/ssh.sh"
                ;;
            4|04)
                menu_connection
                ;;
            5|05)
                run_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/Scrip/blueprint.sh"
                ;;
            6|06)
                menu_cloudflare
                ;;
            7|07)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/theme.sh"
                ;;
            8|08)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/addon.sh"
                ;;
            9|09)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/sshx.sh"
                ;;
            10)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/CtrlPanel.sh"
                ;;
            11)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/code-server.sh"
                ;;
            0|00)
                draw_header
                message OK "Terima kasih sudah menggunakan ManzXD."
                echo
                exit 0
                ;;
            '')
                ;;
            *)
                message ERR "Pilihan tidak valid."
                sleep 1
                ;;
        esac
    done
}

main_menu
