#!/usr/bin/env bash
set -Eeuo pipefail

# ============================================================
#  PTERODACTYL WINGS INSTALLER
#  Version Selector | Docker | Systemd | Optional Configuration
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

RELEASE_API="https://api.github.com/repos/pterodactyl/wings/releases"
INSTALL_PATH="/usr/local/bin/wings"
CONFIG_DIR="/etc/pterodactyl"
SERVICE_FILE="/etc/systemd/system/wings.service"

draw_header() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          PTERODACTYL WINGS INSTALLER                ║"
    echo "║             VERSION SELECTOR                        ║"
    echo "║                  BY MANZ XD                         ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}

pause_screen() {
    echo
    read -r -p "Tekan Enter untuk melanjutkan..."
}

info()    { echo -e "${CYAN}[INFO]${RESET} $*"; }
success() { echo -e "${GREEN}[OK]${RESET} $*"; }
warning() { echo -e "${YELLOW}[WARN]${RESET} $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        error "Jalankan script sebagai root: sudo bash wings-installer.sh"
        exit 1
    fi
}

check_dependencies() {
    for cmd in curl systemctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Perintah '$cmd' belum tersedia."
            exit 1
        fi
    done
}

choose_version() {
    local api="https://api.github.com/repos/pterodactyl/wings/releases?per_page=100"
    local releases_file
    local page=0
    local page_size=10
    local total
    local choice
    local selected
    local start
    local end
    local i

    releases_file="$(mktemp)"

    draw_header
    info "Mengambil daftar versi Wings dari GitHub..."

    if ! curl -fsSL "$api" -o "$releases_file"; then
        rm -f "$releases_file"
        error "Gagal mengambil daftar versi dari GitHub."
        return 1
    fi

    # Pastikan respons API berisi daftar release.
    if ! grep -q '"tag_name"' "$releases_file"; then
        rm -f "$releases_file"
        error "Daftar release kosong atau respons GitHub tidak valid."
        return 1
    fi

    # Ambil tag release dan simpan dalam array.
    mapfile -t WINGS_RELEASES < <(
        grep -oE '"tag_name":[[:space:]]*"[^"]+"' "$releases_file" |
        sed -E 's/.*"([^"]+)"$/\1/'
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

        read -r -p "Pilih nomor versi: " choice

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
                read -r -p "Masukkan tag versi (contoh: v1.11.11): " selected

                if [[ "$selected" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]]; then
                    WINGS_VERSION="$selected"
                    break
                else
                    error "Format versi tidak valid."
                    sleep 1
                fi
                ;;

            0)
                info "Pemilihan versi dibatalkan."
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

    read -r -p "Lanjut install Wings ${WINGS_VERSION}? [y/N]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Instalasi dibatalkan."
        return 1
    fi
}

install_docker() {
    echo
    info "Memeriksa Docker..."

    if command -v docker >/dev/null 2>&1; then
        success "Docker sudah terpasang."
    else
        warning "Docker belum ditemukan."
        read -r -p "Instal Docker stable sekarang? [y/N]: " install_choice

        if [[ "$install_choice" =~ ^[Yy]$ ]]; then
            curl -fsSL https://get.docker.com/ -o /tmp/install-docker.sh
            sh /tmp/install-docker.sh
            rm -f /tmp/install-docker.sh
        else
            error "Docker diperlukan untuk instalasi ini."
            exit 1
        fi
    fi

    systemctl enable --now docker
    success "Docker aktif."
}

update_grub_optional() {
    echo
    warning "Pengaturan GRUB dapat memengaruhi proses boot sistem."
    read -r -p "Terapkan swapaccount=1 pada GRUB seperti script lama? [y/N]: " grub_choice

    if [[ ! "$grub_choice" =~ ^[Yy]$ ]]; then
        info "Pengaturan GRUB dilewati."
        return
    fi

    if [[ -f /etc/default/grub ]] && command -v update-grub >/dev/null 2>&1; then
        cp /etc/default/grub "/etc/default/grub.backup.$(date +%Y%m%d%H%M%S)"

        if grep -q '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub; then
            sed -i \
                's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"/' \
                /etc/default/grub
        else
            echo 'GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1"' >> /etc/default/grub
        fi

        update-grub
        success "GRUB diperbarui. Perubahan kernel berlaku setelah reboot."
    else
        warning "File GRUB atau perintah update-grub tidak ditemukan; dilewati."
    fi
}

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

    if ! curl -fL --retry 3 "$url" -o "$temp_file"; then
        rm -f "$temp_file"
        error "Download gagal. Periksa versi dan arsitektur yang dipilih."
        exit 1
    fi

    chmod 0755 "$temp_file"
    install -m 0755 "$temp_file" "$INSTALL_PATH"
    rm -f "$temp_file"

    if ! "$INSTALL_PATH" version; then
        warning "Binary terpasang, tetapi perintah pemeriksaan versi gagal."
    fi

    success "Wings berhasil diunduh ke $INSTALL_PATH"
}

install_service() {
    mkdir -p "$CONFIG_DIR"

    cat > "$SERVICE_FILE" <<'SERVICE'
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

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
    warning "Wings belum dijalankan sampai konfigurasi tersedia."
}

create_helper() {
    cat > /usr/local/bin/wing <<'HELPER'
#!/usr/bin/env bash
set -e

case "${1:-status}" in
    start)
        sudo systemctl start wings
        ;;
    stop)
        sudo systemctl stop wings
        ;;
    restart)
        sudo systemctl restart wings
        ;;
    status)
        sudo systemctl status wings --no-pager
        ;;
    logs)
        sudo journalctl -u wings -n 100 --no-pager
        ;;
    *)
        echo "Penggunaan: wing {start|stop|restart|status|logs}"
        exit 1
        ;;
esac
HELPER

    chmod 0755 /usr/local/bin/wing
    success "Perintah bantuan 'wing' tersedia."
}

configure_wings() {
    echo
    read -r -p "Mau mengisi konfigurasi Wings sekarang? [y/N]: " auto_config

    if [[ ! "$auto_config" =~ ^[Yy]$ ]]; then
        warning "Konfigurasi dilewati."
        echo "Setelah konfigurasi dari Panel disimpan ke $CONFIG_DIR/config.yml,"
        echo "jalankan: systemctl enable --now wings"
        return
    fi

    echo
    warning "Nilai konfigurasi sebaiknya disalin dari halaman Node di Panel."
    warning "Jangan membagikan token atau isi config.yml kepada orang lain."
    echo

    read -r -p "UUID Node: " UUID
    read -r -p "Token ID: " TOKEN_ID
    read -r -s -p "Token: " TOKEN
    echo
    read -r -p "FQDN Node: " FQDN
    read -r -p "URL Panel (contoh: https://panel.example.com): " REMOTE

    if [[ -z "$UUID" || -z "$TOKEN_ID" || -z "$TOKEN" || -z "$FQDN" || -z "$REMOTE" ]]; then
        error "Ada kolom yang kosong. Konfigurasi dibatalkan."
        return 1
    fi

    if [[ -f "$CONFIG_DIR/config.yml" ]]; then
        cp "$CONFIG_DIR/config.yml" \
            "$CONFIG_DIR/config.yml.backup.$(date +%Y%m%d%H%M%S)"
        warning "Konfigurasi lama dicadangkan."
    fi

    cat > "$CONFIG_DIR/config.yml" <<CFG
debug: false
uuid: ${UUID}
token_id: ${TOKEN_ID}
token: ${TOKEN}
api:
  host: 0.0.0.0
  port: 8080
  ssl:
    enabled: false
    cert: /etc/letsencrypt/live/${FQDN}/fullchain.pem
    key: /etc/letsencrypt/live/${FQDN}/privkey.pem
  upload_limit: 1000
system:
  data: /var/lib/pterodactyl/volumes
  sftp:
    bind_port: 2022
allowed_mounts: []
remote: '${REMOTE}'
CFG

    chmod 0600 "$CONFIG_DIR/config.yml"
    success "Konfigurasi disimpan ke $CONFIG_DIR/config.yml"

    echo
    warning "Konfigurasi ini mengasumsikan TLS ditangani di luar Wings."
    warning "Pastikan alamat, port, sertifikat, dan pengaturan Node cocok dengan Panel."
    read -r -p "Jalankan service Wings sekarang? [y/N]: " start_choice

    if [[ "$start_choice" =~ ^[Yy]$ ]]; then
        systemctl enable --now wings
        systemctl --no-pager --full status wings || true
    else
        info "Belum dijalankan. Jalankan: systemctl start wings"
    fi
}

main() {
    require_root
    check_dependencies
    choose_version

    echo
    warning "Installer akan memasang atau mengganti binary Wings."
    warning "Pastikan versi yang dipilih cocok dengan Panel dan OS kamu."
    read -r -p "Lanjutkan instalasi versi ${WINGS_VERSION}? [y/N]: " confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        info "Instalasi dibatalkan."
        exit 0
    fi

    install_docker
    update_grub_optional
    download_wings
    install_service
    create_helper
    configure_wings

    echo
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════╗"
    echo "║                INSTALLER SELESAI                    ║"
    echo -e "╚══════════════════════════════════════════════════════╝${RESET}"
    echo
    echo "Versi dipilih : $WINGS_VERSION"
    echo "Binary        : $INSTALL_PATH"
    echo "Konfigurasi   : $CONFIG_DIR/config.yml"
    echo "Service       : wings"
    echo
    echo "Cek status    : wing status"
    echo "Lihat log     : wing logs"
    echo
}

main "$@"
