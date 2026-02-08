#!/bin/bash
# FeatherWings Standalone Installer
# Extracted from FeatherPanel Installer

# Check for Root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (sudo)."
    exit 1
fi

# Colors
NC=$'\033[0m'
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
BLUE=$'\033[0;34m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }

echo -e "${CYAN}${BOLD}FeatherWings Installer${NC}"
echo "========================================"

# 1. Update System & Install Dependencies
log_info "Updating package lists and installing dependencies..."
apt-get update -qq
apt-get install -y -qq curl sudo ca-certificates gnupg lsb-release

# 2. Check/Install Docker
if command -v docker &>/dev/null; then
    log_info "Docker is already installed."
else
    log_info "Installing Docker engine..."
    curl -sSL https://get.docker.com/ | CHANNEL=stable bash
    systemctl enable --now docker
    log_success "Docker installed."
fi

# 3. Check Kernel for Swap Support (Optional but recommended)
KERNEL_VERSION=$(uname -r | cut -d. -f1-2)
KERNEL_MAJOR=$(echo "$KERNEL_VERSION" | cut -d. -f1)
KERNEL_MINOR=$(echo "$KERNEL_VERSION" | cut -d. -f2)

if [ "$KERNEL_MAJOR" -lt 6 ] || { [ "$KERNEL_MAJOR" -eq 6 ] && [ "$KERNEL_MINOR" -lt 1 ]; }; then
    log_warn "Kernel version $KERNEL_VERSION detected."
    log_warn "If you need Docker swap support, enable 'swapaccount=1' in GRUB."
else
    log_info "Kernel version $KERNEL_VERSION detected (Swap enabled by default)."
fi

# 4. Create Directory Structure
log_info "Creating FeatherWings directory structure..."
mkdir -p /etc/featherpanel
mkdir -p /var/lib/featherpanel/volumes
mkdir -p /var/lib/featherpanel/archives
mkdir -p /var/lib/featherpanel/backups
mkdir -p /var/log/featherpanel
mkdir -p /tmp/featherpanel
mkdir -p /var/run/featherwings

# 5. Download Wings Binary
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    WINGS_URL="https://github.com/MythicalLTD/FeatherWings/releases/latest/download/wings_linux_amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
    WINGS_URL="https://github.com/MythicalLTD/FeatherWings/releases/latest/download/wings_linux_arm64"
else
    log_error "Unsupported architecture: $ARCH"
    exit 1
fi

log_info "Downloading FeatherWings binary for $ARCH..."
curl -L -o /usr/local/bin/featherwings "$WINGS_URL"
chmod +x /usr/local/bin/featherwings

# 6. Create Systemd Service
log_info "Creating systemd service..."
cat <<EOF > /etc/systemd/system/featherwings.service
[Unit]
Description=FeatherWings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/featherwings
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/featherwings --config /etc/featherwings/config.yml
Restart=on-failure
StartLimitInterval=600

[Install]
WantedBy=multi-user.target
EOF

# 7. Enable and Finalize
systemctl daemon-reload
systemctl enable featherwings

log_success "FeatherWings installed successfully!"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Create a node in your FeatherPanel admin panel."
echo "2. Copy the configuration content."
echo "3. Paste it into: ${BOLD}nano /etc/featherpanel/config.yml${NC}"
echo "4. Start the service: ${BOLD}systemctl start featherwings${NC}"
echo "5. Or run debug mode: ${BOLD}featherwings --debug${NC}"
