#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
# PTERODACTYL WINGS INSTALLER
# MANZ XD
# Automatic Docker + GRUB + Version Selector
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

RELEASE_API="https://api.github.com/repos/pterodactyl/wings/releases?per_page=100"
INSTALL_PATH="/usr/local/bin/wings"
CONFIG_DIR="/etc/pterodactyl"
SERVICE_FILE="/etc/systemd/system/wings.service"

info() {
    echo -e "${CYAN}[INFO]${RESET} $*"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $*"
}

warning() {
    echo -e "${YELLOW}[WARN]${RESET} $*"
}

error() {
    echo -e "${RED}[ERROR]${RESET} $*" >&2
}

draw_header() {
    clear || true

    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          PTERODACTYL WINGS INSTALLER                ║"
    echo "║             VERSION SELECTOR                        ║"
    echo "║                  BY MANZ XD                         ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "Jalankan script sebagai root."
        echo "Contoh: sudo bash wings-installer.sh"
        exit 1
    fi
}

check_dependencies() {
    for cmd in curl python3 systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Perintah $cmd belum tersedia."
            exit 1
        fi
    done
}

# ============================================================
# VERSION SELECTOR
# ============================================================

choose_version() {
    local releases_file
    local choice
    local selected
    local page=0
    local page_size=10
    local total
    local start
    local end
    local i
    local confirm

    releases_file="$(mktemp)"

    draw_header
    info "Mengambil daftar versi Wings dari GitHub..."

    if ! curl -fsSL \
        --connect-timeout 10 \
        --max-time 60 \
        --retry 2 \
        "$RELEASE_API" \
        -o "$releases_file"; then

        rm -f "$releases_file"

        error "Gagal mengambil daftar versi Wings."
        error "Periksa koneksi internet atau batas API GitHub."
        return 1
    fi

    mapfile -t WINGS_RELEASES < <(
        python3 - "$releases_file" <<'PY'
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as f:
        data = json.load(f)

    if not isinstance(data, list):
        sys.exit(1)

    for release in data:
        if release.get("draft", False):
            continue

        tag = release.get("tag_name", "")

        if tag.startswith("v"):
            print(tag)

except Exception:
    sys.exit(1)
PY
    )

    rm -f "$releases_file"

    total=${#WINGS_RELEASES[@]}

    if (( total == 0 )); then
        error "Tidak ada versi Wings yang ditemukan."
        return 1
    fi

    while true; do
        draw_header

        echo -e "${BOLD}PILIH VERSI WINGS${RESET}"
        echo -e "${YELLOW}Release tersedia: ${total}${RESET}"
        echo

        start=$((page * page_size))
        end=$((start + page_size))

        if (( end > total )); then
            end=$total
        fi

        for ((i=start; i<end; i++)); do
            printf "  ${GREEN}[%2d]${RESET} %s\n" \
                "$((i - start + 1))" "${WINGS_RELEASES[$i]}"
        done

        echo
        echo "  [N] Halaman berikutnya"

        if (( page > 0 )); then
            echo "  [P] Halaman sebelumnya"
        fi

        echo "  [M] Masukkan versi manual"
        echo "  [0] Batal"
        echo

        read -r -p "Pilih nomor versi: " choice || return 1

        case "$choice" in
            [Nn])
                if (( end < total )); then
                    page=$((page + 1))
                else
                    warning "Kamu sudah berada di halaman terakhir."
                    sleep 1
                fi
                ;;

            [Pp])
                if (( page > 0 )); then
                    page=$((page - 1))
                else
                    warning "Ini halaman pertama."
                    sleep 1
                fi
                ;;

            [Mm])
                read -r -p \
                    "Masukkan tag versi (contoh: v1.13.4): " selected \
                    || return 1

                if [[ "$selected" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
                    WINGS_VERSION="$selected"
                    break
                else
                    error "Format versi tidak valid."
                    sleep 1
                fi
                ;;

            0)
                info "Instalasi dibatalkan."
                return 1
                ;;

            *)
                if [[ "$choice" =~ ^[0-9]+$ ]] &&
                   (( choice >= 1 && choice <= end - start )); then

                    WINGS_VERSION="${WINGS_RELEASES[$((start + choice - 1))]}"
                    break
                else
                    error "Pilihan tidak valid."
                    sleep 1
                fi
                ;;
        esac
    done

    echo
    success "Versi terpilih: ${WINGS_VERSION}"
    echo

    read -r -p \
        "Lanjut install Wings ${WINGS_VERSION}? [y/N]: " confirm \
        || return 1

    case "${confirm,,}" in
        y|yes)
            success "Melanjutkan instalasi ${WINGS_VERSION}."
            ;;
        *)
            info "Instalasi dibatalkan."
            return 1
            ;;
    esac
}

# ============================================================
# INSTALL DOCKER AUTOMATICALLY
# ============================================================

install_docker() {
    echo
    info "Memeriksa Docker..."

    if ! command -v docker >/dev/null 2>&1; then
        warning "Docker belum terpasang."
        info "Menginstal Docker menggunakan installer resmi..."

        local installer="/tmp/install-docker.sh"

        if ! curl -fsSL \
            --connect-timeout 10 \
            --max-time 120 \
            https://get.docker.com/ \
            -o "$installer"; then

            rm -f "$installer"
            error "Gagal mengunduh installer Docker."
            exit 1
        fi

        if ! sh "$installer"; then
            rm -f "$installer"
            error "Instalasi Docker gagal."
            exit 1
        fi

        rm -f "$installer"
    else
        success "Docker sudah terpasang."
    fi

    if ! systemctl enable --now docker; then
        error "Docker gagal diaktifkan."
        systemctl status docker --no-pager || true
        exit 1
    fi

    if ! docker info >/dev/null 2>&1; then
        error "Docker belum siap digunakan."
        systemctl status docker --no-pager || true
        exit 1
    fi

    success "Docker aktif dan siap digunakan."
}

# ============================================================
# GRUB AUTOMATICALLY
# Preserve existing kernel parameters.
# ============================================================

update_grub_automatic() {
    echo
    info "Memeriksa pengaturan GRUB..."

    if [[ ! -f /etc/default/grub ]]; then
        warning "File /etc/default/grub tidak ditemukan. Dilewati."
        return 0
    fi

    if ! command -v update-grub >/dev/null 2>&1; then
        warning "Perintah update-grub tidak ditemukan. Dilewati."
        return 0
    fi

    local current
    local backup

    current="$(
        sed -n \
            's/^GRUB_CMDLINE_LINUX_DEFAULT="\([^"]*\)".*/\1/p' \
            /etc/default/grub | head -n 1
    )"

    if [[ "$current" == *"swapaccount=1"* ]]; then
        success "swapaccount=1 sudah tersedia di GRUB."
        return 0
    fi

    backup="/etc/default/grub.backup.$(date +%Y%m%d%H%M%S)"

    cp -a /etc/default/grub "$backup"

    info "Backup GRUB: $backup"

    if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
        python3 - /etc/default/grub <<'PY'
import re
import sys

path = sys.argv[1]

with open(path, encoding="utf-8") as f:
    text = f.read()

pattern = r'^GRUB_CMDLINE_LINUX_DEFAULT="([^"]*)"'

def update(match):
    value = match.group(1).strip()
    if "swapaccount=1" not in value.split():
        value = (value + " swapaccount=1").strip()
    return 'GRUB_CMDLINE_LINUX_DEFAULT="' + value + '"'

updated, count = re.subn(
    pattern,
    update,
    text,
    count=1,
    flags=re.MULTILINE
)

if count == 0:
    print("Tidak dapat membaca parameter GRUB.", file=sys.stderr)
    sys.exit(1)

with open(path, "w", encoding="utf-8") as f:
    f.write(updated)
PY

    else
        echo 'GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"' \
            >> /etc/default/grub
    fi

    if update-grub; then
        success "GRUB berhasil diperbarui."
        warning "Perubahan kernel berlaku setelah reboot."
    else
        cp -a "$backup" /etc/default/grub
        error "update-grub gagal. Konfigurasi GRUB dikembalikan."
        return 1
    fi
}

# ============================================================
# DOWNLOAD WINGS
# ============================================================

download_wings() {
    local arch
    local url
    local temp_file

    case "$(uname -m)" in
        x86_64|amd64)
            arch="amd64"
            ;;
        aarch64|arm64)
            arch="arm64"
            ;;
        *)
            error "Arsitektur tidak didukung: $(uname -m)"
            exit 1
            ;;
    esac

    url="https://github.com/pterodactyl/wings/releases/download/${WINGS_VERSION}/wings_linux_${arch}"

    temp_file="$(mktemp)"

    echo
    info "Mengunduh Wings ${WINGS_VERSION} untuk ${arch}..."

    if ! curl -fL \
        --connect-timeout 10 \
        --max-time 180 \
        --retry 3 \
        "$url" \
        -o "$temp_file"; then

        rm -f "$temp_file"

        error "Download Wings gagal."
        error "Periksa versi dan arsitektur yang dipilih."
        exit 1
    fi

    chmod 0755 "$temp_file"
    install -m 0755 "$temp_file" "$INSTALL_PATH"
    rm -f "$temp_file"

    if ! "$INSTALL_PATH" version; then
        error "Binary Wings tidak dapat dijalankan."
        exit 1
    fi

    success "Wings berhasil dipasang di $INSTALL_PATH"
}

# ============================================================
# SYSTEMD SERVICE
# ============================================================

install_service() {
    mkdir -p "$CONFIG_DIR"

    cat > "$SERVICE_FILE" <<'SERVICE'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
ExecStart=/usr/local/bin/wings
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl daemon-reload
    systemctl enable wings

    success "Service Wings dibuat dan diaktifkan saat boot."
    warning "Wings akan dijalankan setelah config.yml tersedia."
}

# ============================================================
# HELPER COMMAND
# ============================================================

create_helper() {
    cat > /usr/local/bin/wing <<'HELPER'
#!/usr/bin/env bash
set -e

case "${1:-status}" in
    start)
        systemctl start wings
        ;;
    stop)
        systemctl stop wings
        ;;
    restart)
        systemctl restart wings
        ;;
    status)
        systemctl status wings --no-pager
        ;;
    logs)
        journalctl -u wings -n 100 --no-pager
        ;;
    *)
        echo "Penggunaan: wing {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
HELPER

    chmod 0755 /usr/local/bin/wing

    success "Perintah bantuan wing tersedia."
}

# ============================================================
# WINGS CONFIGURATION
# ============================================================

configure_wings() {
    local manual_choice

    echo
    echo "============================================================"
    echo " KONFIGURASI WINGS"
    echo "============================================================"
    echo
    echo "Konfigurasi Wings sebaiknya diambil dari halaman Node di Panel."
    echo "Jangan membuat UUID, token, port, atau SSL secara sembarangan."
    echo

    read -r -p \
        "Mau konfigurasi Wings secara manual sekarang? [y/N]: " \
        manual_choice || return 1

    case "${manual_choice,,}" in
        y|yes)
            echo
            info "Konfigurasi manual dipilih."
            echo
            echo "Langkah berikutnya:"
            echo "1. Buka Panel Pterodactyl."
            echo "2. Masuk ke Admin > Nodes."
            echo "3. Pilih Node yang akan digunakan."
            echo "4. Buka Configuration."
            echo "5. Salin konfigurasi yang dibuat Panel."
            echo "6. Simpan konfigurasi ke:"
            echo "   $CONFIG_DIR/config.yml"
            echo
            warning "Jangan membagikan token atau config.yml kepada orang lain."
            ;;

        n|no|"")
            echo
            info "Konfigurasi Wings dilewati."
            echo
            echo "Kamu bisa mengatur Node dari Panel nanti."
            echo "Setelah mendapatkan konfigurasi yang benar, simpan ke:"
            echo "  $CONFIG_DIR/config.yml"
            ;;

        *)
            warning "Pilihan tidak dikenali. Konfigurasi dilewati."
            ;;
    esac

    echo

    if [[ -s "$CONFIG_DIR/config.yml" ]]; then
        success "config.yml ditemukan."

        local start_choice

        read -r -p \
            "Jalankan Wings sekarang? [y/N]: " start_choice || return 1

        case "${start_choice,,}" in
            y|yes)
                if systemctl restart wings; then
                    sleep 2
                    systemctl --no-pager --full status wings || true
                else
                    error "Wings gagal dijalankan."
                    journalctl -u wings -n 50 --no-pager || true
                fi
                ;;
            *)
                info "Service belum dijalankan."
                ;;
        esac
    else
        warning "config.yml belum tersedia."
        info "Wings tidak dijalankan sampai konfigurasi yang benar tersedia."
    fi
}

# ============================================================
# MAIN
# ============================================================

main() {
    require_root
    check_dependencies

    choose_version || exit 0

    echo
    warning "Installer akan memasang atau mengganti binary Wings."
    warning "Pastikan versi yang dipilih cocok dengan Panel dan OS kamu."
    echo

    install_docker
    update_grub_automatic
    download_wings
    install_service
    create_helper
    configure_wings

    echo
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                INSTALLER SELESAI                    ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"

    echo "Versi Wings  : $WINGS_VERSION"
    echo "Binary       : $INSTALL_PATH"
    echo "Konfigurasi  : $CONFIG_DIR/config.yml"
    echo "Service      : wings"
    echo
    echo "Cek status   : wing status"
    echo "Lihat log    : wing logs"
    echo "Mulai        : wing start"
    echo "Restart      : wing restart"
    echo
}

main "$@"
