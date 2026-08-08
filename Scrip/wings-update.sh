#!/bin/bash
set -e

echo "========================================"
echo "       PTERODACTYL WINGS UPDATER"
echo "========================================"
echo ""

# ------------------------
# 1. Check root
# ------------------------
if [ "$EUID" -ne 0 ]; then
    echo "[!] Please run this script as root."
    echo "    sudo bash update-wings.sh"
    exit 1
fi

# ------------------------
# 2. Check Wings
# ------------------------
if [ ! -f /usr/local/bin/wings ]; then
    echo "[!] Wings binary not found!"
    echo "    Expected: /usr/local/bin/wings"
    exit 1
fi

# ------------------------
# 3. Detect architecture
# ------------------------
ARCH=$(uname -m)

case "$ARCH" in
    x86_64)
        ARCH="amd64"
        ;;
    aarch64|arm64)
        ARCH="arm64"
        ;;
    *)
        echo "[!] Unsupported architecture: $(uname -m)"
        exit 1
        ;;
esac

echo "[*] Architecture: $ARCH"

# ------------------------
# 4. Show current version
# ------------------------
echo ""
echo "[*] Current Wings version:"
/usr/local/bin/wings --version || true

# ------------------------
# 5. Backup current binary
# ------------------------
BACKUP="/usr/local/bin/wings.backup.$(date +%Y%m%d-%H%M%S)"

echo ""
echo "[*] Backing up current Wings..."
cp /usr/local/bin/wings "$BACKUP"

echo "[+] Backup created:"
echo "    $BACKUP"

# ------------------------
# 6. Stop Wings
# ------------------------
echo ""
echo "[*] Stopping Wings..."
systemctl stop wings || true

# ------------------------
# 7. Download latest Wings
# ------------------------
echo ""
echo "[*] Downloading latest Wings..."

TEMP="/tmp/wings_new"

if ! curl -fL \
    -o "$TEMP" \
    "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_${ARCH}"; then

    echo "[!] Failed to download latest Wings."
    echo "[*] Starting previous Wings..."

    systemctl start wings || true

    exit 1
fi

# ------------------------
# 8. Validate downloaded file
# ------------------------
echo "[*] Validating downloaded binary..."

if [ ! -s "$TEMP" ]; then
    echo "[!] Downloaded Wings file is empty!"
    rm -f "$TEMP"

    echo "[*] Starting previous Wings..."
    systemctl start wings || true

    exit 1
fi

# ------------------------
# 9. Install new binary
# ------------------------
echo "[*] Installing latest Wings..."

mv "$TEMP" /usr/local/bin/wings
chmod u+x /usr/local/bin/wings

# ------------------------
# 10. Check version
# ------------------------
echo ""
echo "[*] New Wings version:"

if ! /usr/local/bin/wings --version; then
    echo ""
    echo "[!] New Wings binary failed!"
    echo "[*] Restoring backup..."

    cp "$BACKUP" /usr/local/bin/wings
    chmod u+x /usr/local/bin/wings

    systemctl start wings

    exit 1
fi

# ------------------------
# 11. Reload systemd
# ------------------------
echo ""
echo "[*] Reloading systemd..."
systemctl daemon-reload

# ------------------------
# 12. Start Wings
# ------------------------
echo "[*] Starting Wings..."
systemctl start wings

sleep 3

# ------------------------
# 13. Check service
# ------------------------
echo ""
if systemctl is-active --quiet wings; then
    echo "========================================"
    echo "       WINGS UPDATE SUCCESSFUL"
    echo "========================================"
    echo ""
    echo "[+] Wings is running."
    echo ""
    systemctl --no-pager --full status wings
else
    echo "========================================"
    echo "       WINGS FAILED TO START"
    echo "========================================"
    echo ""

    systemctl --no-pager --full status wings

    echo ""
    echo "[!] Restoring previous Wings..."

    systemctl stop wings || true
    cp "$BACKUP" /usr/local/bin/wings
    chmod u+x /usr/local/bin/wings

    systemctl start wings

    echo ""
    echo "[!] Previous Wings version restored."
    exit 1
fi
