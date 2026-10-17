#!/usr/bin/env bash

# ============================================================
#  MANZXD - DOCKER OS CONTROL CENTER
#  Premium CLI Edition
# ============================================================

APP_NAME="MANZXD DOCKER OS"
APP_VERSION="3.1"

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
    GREEN='' RED='' YELLOW='' WHITE='' GREY=''
fi

trap 'printf "\n%b\n" "${YELLOW}[!] Console dihentikan.${RESET}"; exit 130' INT

# ---------- BASIC UTILITIES ----------
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
    printf '  %b[%s]%b %s\n' "${GREEN}${BOLD}" "$1" "${RESET}" "$2"
}

prompt_choice() {
    printf '\n'
    printf '  %b' "${CYAN}${BOLD}MANZXD ${RESET}${GREY}» ${RESET}"
    read -r REPLY
    REPLY="${REPLY//[[:space:]]/}"
}

# ---------- DEPENDENCIES ----------
check_curl() {
    command -v curl >/dev/null 2>&1 && return 0

    message WARN "curl belum tersedia."

    if [[ $EUID -ne 0 ]]; then
        message ERR "Jalankan console sebagai root untuk memasang curl."
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

# ---------- SCRIPT RUNNER ----------
run_script() {
    local url="$1"
    local file
    local status

    if [[ -z "$url" ]]; then
        message ERR "URL tidak tersedia."
        pause
        return 1
    fi

    if ! check_curl; then
        pause
        return 1
    fi

    file=$(mktemp "${TMPDIR:-/tmp}/manzxd.XXXXXX") || {
        message ERR "Gagal mempersiapkan proses."
        pause
        return 1
    }

    # Download tanpa menampilkan URL atau pesan proses.
    if ! curl --fail --location --silent --show-error \
        --connect-timeout 15 \
        --max-time 180 \
        --output "$file" "$url"; then
        message ERR "Proses gagal. Periksa koneksi atau sumber script."
        rm -f "$file"
        pause
        return 1
    fi

    if [[ ! -s "$file" ]]; then
        message ERR "File script kosong."
        rm -f "$file"
        pause
        return 1
    fi

    # Eksekusi script yang dipilih.
    bash "$file"
    status=$?

    rm -f "$file"

    echo
    if (( status == 0 )); then
        message OK "Proses selesai."
    else
        message ERR "Proses gagal dengan kode $status."
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
            draw_item "$((i + 1))" "${labels[$i]}"
        done

        line
        draw_item "0" "Kembali ke menu utama"

        prompt_choice
        choice="$REPLY"

        case "$choice" in
            0)
                return
                ;;
            '')
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

# ---------- WINGS ----------
menu_wings() {
    submenu "WINGS INSTALLER" \
        "Wings Pterodactyl Original" \
        "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/Scrip/wings.sh" \
        "Wings Pterodactyl Update" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/wings-update.sh" \
        "Wings FeatherPanel" \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/FeatherWings.sh"
}

# ---------- CONNECTION ----------
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

# ---------- CLOUDFLARE ----------
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
        draw_item "1" "Panel Pterodactyl"
        draw_item "2" "Wings Installer                 [SUBMENU]"
        draw_item "3" "SSH Connect"
        draw_item "4" "Connection & Tunnel Tools       [SUBMENU]"
        draw_item "5" "Blueprint Framework"
        draw_item "6" "Cloudflare Tools                [SUBMENU]"

        draw_section "CUSTOMIZATION & ADDONS"
        draw_item "7" "Pasang Tema"
        draw_item "8" "Install Addon"
        draw_item "9" "Install SSHX"
        draw_item "10" "Install CtrlPanel"
        draw_item "11" "Install Code-Server"

        draw_section "SYSTEM"
        draw_item "0" "Keluar dari console"

        prompt_choice
        choice="$REPLY"

        case "$choice" in
            1)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/panel.sh"
                ;;
            2)
                menu_wings
                ;;
            3)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/ssh.sh"
                ;;
            4)
                menu_connection
                ;;
            5)
                run_script "https://raw.githubusercontent.com/buszz71/DockerOS/refs/heads/main/Scrip/blueprint.sh"
                ;;
            6)
                menu_cloudflare
                ;;
            7)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/theme.sh"
                ;;
            8)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/addon.sh"
                ;;
            9)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/sshx.sh"
                ;;
            10)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/CtrlPanel.sh"
                ;;
            11)
                run_script "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/code-server.sh"
                ;;
            0)
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
