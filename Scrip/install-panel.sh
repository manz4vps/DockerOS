#!/bin/bash

# --- MANZVPS NEON THEME ---
CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
YELLOW='\033[38;5;226m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"
GITHUB_REPO="pterodactyl/panel"
PHP_VERSION="8.3"

# --- UI HELPERS ---
step() { echo -e "\n  ${CYAN}▶ $*${NC}"; }
ok()   { echo -e "  ${GREEN}✓ $*${NC}"; }

show_banner() {
    clear
    echo -e "${CYAN}"
    echo "========================================"
    echo ""
    echo "              ManzVMe"
    echo ""
    echo "       PANEL INSTALLER 🇵🇸🇮🇩"
    echo "       LOCATION: SINGAPORE 🇸🇬"
    echo ""
    echo "========================================"
    echo -e "${NC}"
}

# --- INPUT FUNCTION: NO TIMEOUT ---
ask() {
    local label="$1"
    local default="$2"
    local var_name="$3"
    local input

    printf "  ${PURPLE}•${NC} ${WHITE}%s${NC} ${GRAY}[%s]${NC}\n  ${GRAY}╰─>${NC} " "$label" "$default"
    IFS= read -r input || return 1

    if [[ -z "$input" ]]; then
        printf -v "$var_name" '%s' "$default"
    else
        printf -v "$var_name" '%s' "$input"
    fi
}

# --- PASSWORD INPUT: NO TIMEOUT ---
ask_timeout() {
    local label="$1"
    local default="$2"
    local var_name="$3"
    local input

    printf "  ${PURPLE}•${NC} ${WHITE}%s${NC} ${GRAY}[Enter = default]${NC}\n  ${GRAY}╰─>${NC} " "$label"
    IFS= read -r -s input || return 1
    echo

    if [[ -z "$input" ]]; then
        printf -v "$var_name" '%s' "$default"
    else
        printf -v "$var_name" '%s' "$input"
    fi
}

# --- FETCH GITHUB VERSIONS ---
fetch_github_versions() {
    local repo="$1"
    echo -e "  ${GRAY}Fetching releases from ${WHITE}${repo}${GRAY}...${NC}" >&2

    local json
    json=$(curl -fsSL --connect-timeout 10 --max-time 30 \
        "https://api.github.com/repos/${repo}/releases?per_page=20" 2>/dev/null) || {
        echo -e "  ${RED}Failed to fetch releases from GitHub.${NC}" >&2
        return 1
    }

    printf '%s' "$json" | python3 -c '
import sys, json
try:
    data = json.load(sys.stdin)
    for release in data:
        if release.get("prerelease", False) or release.get("draft", False):
            continue
        tag = release.get("tag_name", "")
        if tag.startswith("v"):
            print(tag)
except Exception:
    sys.exit(1)
' 2>/dev/null
}

# --- VERSION SELECTOR: NO TIMEOUT ---
select_version() {
    local repo="$1"
    local var_name="$2"
    local tags=()
    local tag
    local choice
    local i=0

    echo -e "\n  ${PURPLE}::${NC} ${WHITE}Available Panel Versions${NC}"

    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        tags+=("$tag")
        i=$((i + 1))
    done < <(fetch_github_versions "$repo")

    if [[ ${#tags[@]} -eq 0 ]]; then
        echo -e "  ${YELLOW}No versions fetched. Please check your internet/GitHub access.${NC}"
        echo -e "  ${YELLOW}Using the latest release download.${NC}"
        printf -v "$var_name" '%s' "latest"
        return 0
    fi

    for i in "${!tags[@]}"; do
        printf "  ${GRAY}%d.${NC} ${WHITE}%s${NC}\n" "$((i + 1))" "${tags[$i]}"
    done

    local max=${#tags[@]}
    while true; do
        printf "\n  ${PURPLE}•${NC} ${WHITE}Select version [1-%d]${NC} ${GRAY}[1 = latest]${NC}\n  ${GRAY}╰─>${NC} " "$max"

        # No timeout: wait until the user presses Enter.
        IFS= read -r choice || {
            echo -e "\n  ${RED}Input closed; cannot select a version.${NC}"
            return 1
        }

        if [[ -z "$choice" ]]; then
            choice=1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= max )); then
            local idx=$((choice - 1))
            printf "  ${GREEN}→ %s${NC}\n" "${tags[$idx]}"
            printf -v "$var_name" '%s' "${tags[$idx]}"
            return 0
        fi

        echo -e "  ${RED}Invalid choice. Enter a number from 1 to ${max}.${NC}"
    done
}

# --- START ---
show_banner

# --- DATA COLLECTION ---
ask "Panel Domain" "panel.manzvps.com" DOMAIN || exit 1
ask "Admin Email" "admin@gmail.com" EMAIL || exit 1
ask "Admin Username" "admin" USERNAME || exit 1
ask_timeout "Admin Password" "admin" PASSWORD || exit 1
select_version "$GITHUB_REPO" "version_PANEL" || exit 1

# --- FINAL VALIDATION ---
echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}   $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}    $EMAIL"
echo -e "  ${GOLD}│${NC} ${GRAY}User:${NC}     $USERNAME"
echo -e "  ${GOLD}│${NC} ${GRAY}Version:${NC}  $version_PANEL"
echo -e "  ${GOLD}└───────────────────────────${NC}"

# --- CONFIRMATION: NO TIMEOUT, REQUIRES ENTER ---
while true; do
    printf "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}: ${NC}"
    CONFIRM=""

    IFS= read -r CONFIRM || {
        echo -e "\n  ${RED}Input closed. Installation cancelled.${NC}"
        exit 1
    }

    case "${CONFIRM,,}" in
        y|yes)
            echo -e "  ${GREEN}Proceeding to deployment...${NC}"
            break
            ;;
        n|no)
            echo -e "  ${RED}Installation aborted by user.${NC}"
            exit 0
            ;;
        *)
            echo -e "  ${GRAY}Invalid input. Type y or n, then press Enter.${NC}"
            ;;
    esac
done

echo -e "${HEADER_LINE}"

# --- DEPENDENCIES ---
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release python3
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to install base dependencies.${NC}"
    exit 1
fi

# Detect OS
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')

if [[ "$OS" == "ubuntu" ]]; then
    echo "Detected Ubuntu. Adding PPA for PHP..."
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    echo "Detected Debian. Adding SURY PHP repo..."
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
else
    echo -e "${RED}Unsupported OS: ${OS}. Use supported Debian/Ubuntu.${NC}"
    exit 1
fi

# Add Redis GPG key and repo
rm -f /usr/share/keyrings/redis-archive-keyring.gpg
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list

apt update

# --- Install PHP + extensions ---
apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Package installation failed.${NC}"
    exit 1
fi

# --- Install Composer ---
curl -fsSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# --- Download Pterodactyl Panel ---
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl || exit 1

if [[ "$version_PANEL" == "latest" ]]; then
    step "Downloading latest panel release..."
    curl -fLso panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
else
    step "Downloading panel version $version_PANEL..."
    curl -fLso panel.tar.gz "https://github.com/pterodactyl/panel/releases/download/${version_PANEL}/panel.tar.gz"
fi

if [[ $? -ne 0 ]]; then
    echo -e "${RED}Failed to download Panel release.${NC}"
    exit 1
fi

tar -xzf panel.tar.gz || exit 1
chmod -R 755 storage/* bootstrap/cache/

# --- MariaDB Setup ---
DB_NAME=panel
DB_USER=pterodactyl
DB_PASS="CHANGE_THIS_TO_A_STRONG_DATABASE_PASSWORD"
echo -e "${GOLD}IMPORTANT: Change DB_PASS in this script to a strong unique password before installation.${NC}"
mariadb -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1';"
mariadb -e "FLUSH PRIVILEGES;"

# --- .env Setup ---
if [[ ! -f ".env.example" ]]; then
    curl -fLo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
fi
cp .env.example .env
sed -i "s|^APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
if ! grep -q "^APP_ENVIRONMENT_ONLY=" .env; then
    echo "APP_ENVIRONMENT_ONLY=false" >> .env
fi

# --- Install PHP dependencies ---
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
if [[ $? -ne 0 ]]; then
    echo -e "${RED}Composer install failed.${NC}"
    exit 1
fi

# --- Generate Application Key ---
php artisan key:generate --force

# --- Run Migrations ---
php artisan migrate --seed --force

# --- Permissions and schedule ---
chown -R www-data:www-data /var/www/pterodactyl
apt install -y cron
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# --- Nginx Setup ---
mkdir -p /etc/certs/panel
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem

tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
nginx -t && systemctl restart nginx

# --- Queue Worker ---
tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
ok "Queue running"

clear
step "Create admin user"

cd /var/www/pterodactyl || exit 1

# Update .env settings
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env
echo "APP_ENVIRONMENT_ONLY=false" >> .env
sed -i '/^RECAPTCHA_ENABLED=/d' .env
echo 'RECAPTCHA_ENABLED=false' >> .env
sed -i '/^APP_NAME=/d' .env
echo 'APP_NAME="ManzVPS🇵🇸🇮🇩"' >> .env

TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
sed -i "s|^APP_TIMEZONE=.*|APP_TIMEZONE=${TIMEZONE}|g" .env

# SMTP defaults (configure SMTP separately if needed)
sed -i '/^MAIL_MAILER=/d' .env
echo 'MAIL_MAILER=log' >> .env
sed -i '/^MAIL_FROM_NAME=/d' .env
echo 'MAIL_FROM_NAME="ManzVPS🇵🇸🇮🇩"' >> .env

# Singapore location
php artisan p:location:make --short=SGP --long="Singapore" 2>/dev/null || true

# --- Cache optimization ---
php artisan view:clear
php artisan config:clear
php artisan cache:clear
php artisan config:cache
chown -R www-data:www-data /var/www/pterodactyl
php artisan queue:restart

# --- Admin User ---
php artisan p:user:make -n --email="$EMAIL" --username="${USERNAME}" --password="$PASSWORD" --admin=1 --name-first=My --name-last=Admin

# --- END REPORT ---
clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}MANZVPS DEPLOYMENT COMPLETE 🇵🇸🇮🇩${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://${DOMAIN}${NC}"
echo -e "  ${GRAY}Username  :${NC} ${WHITE}${USERNAME}${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}${EMAIL}${NC}"
echo -e "  ${GRAY}Location  :${NC} ${WHITE}Singapore (SGP) 🇸🇬${NC}"
echo -e "\n  ${PURPLE}Welcome to ManzVPS!${NC}"
echo -e "${HEADER_LINE}"
echo -e "${GOLD}For security, the admin password is not printed. Keep it somewhere safe.${NC}"
