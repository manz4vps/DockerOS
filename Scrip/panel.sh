#!/bin/bash

# ================================================================
#                  PTERODACTYL CONTROL CENTER
#                    Professional Edition
#                       Credits: ManzVPS
# ================================================================

# --- COLORS & STYLING ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'
GOLD='\033[0;33m'
GRAY='\033[0;90m'
DIM='\033[2m'

# ================================================================
#                         UI HELPERS
# ================================================================

show_header() {
    clear

    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo -e "║        ${WHITE}${BOLD}⚡ PTERODACTYL CONTROL CENTER${NC}${PURPLE}                  ║"
    echo -e "║        ${GRAY}Professional Server Management System${NC}${PURPLE}          ║"
    echo "║                                                              ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo -e "║  ${CYAN}MODULE${NC}${PURPLE}      : ${WHITE}$1${PURPLE}"
    echo -e "║  ${CYAN}CREDITS${NC}${PURPLE}     : ${WHITE}ManzVPS${PURPLE}"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

status_msg() {
    case $1 in
        "OK")   echo -e "  ${GREEN}[ ✔ ]${NC} $2" ;;
        "ERR")  echo -e "  ${RED}[ ✘ ]${NC} $2" ;;
        "INFO") echo -e "  ${CYAN}[ ➜ ]${NC} $2" ;;
        "WAIT") echo -e "  ${YELLOW}[ ⏳ ]${NC} $2" ;;
    esac
}

section() {
    echo ""
    echo -e "  ${PURPLE}┌─[ ${WHITE}${BOLD}$1${NC}${PURPLE} ]────────────────────────────────────────────────┐${NC}"
}

section_end() {
    echo -e "  ${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
}

pause() {
    echo ""
    echo -ne "  ${GRAY}Press [Enter] to return to main menu...${NC}"
    read
}

# ================================================================
#                     PANEL INSTALLATION
# ================================================================

install_ptero() {
    show_header "PANEL INSTALLATION"

    section "INSTALLATION"

    status_msg "INFO" "Initiating Pterodactyl installation script..."
    status_msg "INFO" "Please follow the installer instructions below."

    section_end

    sleep 1

    bash <(curl -fsSL https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-panel.sh)

    echo ""
    status_msg "INFO" "Installation script finished. Check its output for errors."

    pause
}

# ================================================================
#                       USER MANAGEMENT
# ================================================================

create_user() {
    show_header "USER MANAGEMENT"

    if [ ! -d /var/www/pterodactyl ]; then
        section "PANEL STATUS"

        status_msg "ERR" "Panel directory not found."
        status_msg "ERR" "/var/www/pterodactyl does not exist."
        status_msg "INFO" "Please install the panel first."

        section_end

        pause
        return
    fi

    section "CREATE USER"

    echo -e "  ${GREEN}[1]${NC} ${WHITE}Custom User Create${NC}"
    echo -e "      ${GRAY}Manual Pterodactyl user creation${NC}"
    echo ""

    echo -e "  ${GREEN}[2]${NC} ${WHITE}Auto Create Admin User${NC}"
    echo -e "      ${GRAY}Automatically generate admin credentials${NC}"
    echo ""

    section_end

    echo ""
    echo -ne "  ${CYAN}${BOLD}root@ptero${NC}${GRAY}:~#${NC} "
    read -r choice

    cd /var/www/pterodactyl || return

    if [ "$choice" = "1" ]; then
        show_header "USER MANAGEMENT"

        status_msg "WAIT" "Launching manual user creation..."
        php artisan p:user:make

    elif [ "$choice" = "2" ]; then
        show_header "USER MANAGEMENT"

        status_msg "WAIT" "Creating auto admin user..."

        USERNAME="user$(openssl rand -hex 2)"
        PASSWORD="$(openssl rand -base64 10)"
        EMAIL="$(openssl rand -hex 4)@example.com"
        FIRST="Panel"
        LAST="Admin"

        php artisan p:user:make -n \
            --email="${EMAIL}" \
            --username="${USERNAME}" \
            --password="${PASSWORD}" \
            --admin=1 \
            --name-first="${FIRST}" \
            --name-last="${LAST}"

        echo ""

        section "GENERATED CREDENTIALS"

        echo -e "  ${CYAN}Username${NC} : ${WHITE}$USERNAME${NC}"
        echo -e "  ${CYAN}Password${NC} : ${WHITE}$PASSWORD${NC}"
        echo -e "  ${CYAN}Email${NC}    : ${WHITE}$EMAIL${NC}"

        section_end

        echo ""
        status_msg "INFO" "Check the command output to confirm user creation."

    else
        status_msg "ERR" "Invalid option."
    fi

    pause
}

# ================================================================
#                      PANEL UNINSTALL
# ================================================================

uninstall_logic() {
    section "REMOVING PANEL SERVICES"

    status_msg "WAIT" "Stopping Panel services..."

    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl daemon-reload

    status_msg "OK" "Panel service stopped."

    section_end

    section "CLEANING CRONJOBS"

    status_msg "WAIT" "Removing cronjobs..."

    crontab -l 2>/dev/null |
        grep -v 'php /var/www/pterodactyl/artisan schedule:run' |
        crontab - 2>/dev/null || true

    status_msg "OK" "Cronjobs cleaned."

    section_end

    section "REMOVING PANEL FILES"

    status_msg "WAIT" "Deleting panel files..."

    rm -rf /var/www/pterodactyl

    status_msg "OK" "Panel files removed."

    section_end

    section "DATABASE CLEANUP"

    status_msg "WAIT" "Dropping database and users..."

    mysql -u root -e "DROP DATABASE IF EXISTS panel;"
    mysql -u root -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';"
    mysql -u root -e "FLUSH PRIVILEGES;"

    status_msg "OK" "Database cleanup commands completed."

    section_end

    section "NGINX CLEANUP"

    status_msg "WAIT" "Cleaning Nginx configs..."

    rm -f /etc/nginx/sites-enabled/pterodactyl.conf
    rm -f /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx || true

    status_msg "OK" "Nginx configuration cleaned."

    section_end
}

uninstall_ptero() {
    show_header "UNINSTALLATION"

    echo -e "  ${RED}${BOLD}⚠ DANGER ZONE${NC}"
    echo ""

    echo -e "  ${RED}This operation will permanently remove:${NC}"
    echo -e "  ${GRAY}•${NC} Pterodactyl panel files"
    echo -e "  ${GRAY}•${NC} Panel database"
    echo -e "  ${GRAY}•${NC} Pterodactyl database user"
    echo -e "  ${GRAY}•${NC} Panel service configuration"
    echo -e "  ${GRAY}•${NC} Nginx panel configuration"
    echo ""

    echo -e "  ${GREEN}Wings will remain untouched.${NC}"
    echo ""
    echo -e "  ${RED}Back up your panel files and database first.${NC}"
    echo -e "  ${RED}────────────────────────────────────────────────────────────${NC}"

    echo -ne "  ${RED}${BOLD}Are you sure? (y/N):${NC} "
    read -r confirm

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        status_msg "INFO" "Uninstallation cancelled."
        pause
        return
    fi

    echo ""
    uninstall_logic
    echo ""

    section "FINAL STATUS"

    status_msg "INFO" "Uninstallation commands have finished."
    status_msg "INFO" "Review command output for any errors."
    status_msg "INFO" "Wings remains untouched."

    section_end
    pause
}

# ================================================================
#                         UPDATE PANEL
# ================================================================

update_panel() {
    show_header "SYSTEM UPDATE"

    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel not found in /var/www/pterodactyl"
        pause
        return
    fi

    echo -e "  ${RED}${BOLD}WARNING:${NC} Updating can replace panel files."
    echo -e "  ${YELLOW}Back up panel files and database before proceeding.${NC}"
    echo ""

    echo -ne "  ${CYAN}Continue with update? (y/N): ${NC}"
    read -r update_confirm

    if [[ "$update_confirm" != "y" && "$update_confirm" != "Y" ]]; then
        status_msg "INFO" "Update cancelled."
        pause
        return
    fi

    GITHUB_REPO="pterodactyl/panel"

    fetch_github_versions() {
        local repo=$1
        local json

        json=$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=20") || {
            status_msg "ERR" "Failed to fetch releases."
            return 1
        }

        python3 -c '
import sys, json
data = json.load(sys.stdin)
for release in data:
    if not release.get("prerelease", False):
        tag = release.get("tag_name", "")
        if tag.startswith("v"):
            print(tag)
' <<< "$json"
    }

    local tags=()
    while IFS= read -r tag; do
        [[ -n "$tag" ]] && tags+=("$tag")
    done < <(fetch_github_versions "$GITHUB_REPO")

    if [[ ${#tags[@]} -eq 0 ]]; then
        status_msg "ERR" "No releases found. Update cancelled."
        pause
        return
    fi

    echo ""
    echo -e "  ${WHITE}${BOLD}Available Panel Versions${NC}"

    for i in "${!tags[@]}"; do
        printf "  [%d] %s\n" "$((i + 1))" "${tags[$i]}"
    done

    echo ""
    echo -ne "  ${CYAN}Select version [1-${#tags[@]}] (default 1): ${NC}"
    read -r version_choice

    [[ -z "$version_choice" ]] && version_choice=1

    if ! [[ "$version_choice" =~ ^[0-9]+$ ]] ||
       (( version_choice < 1 || version_choice > ${#tags[@]} )); then
        status_msg "ERR" "Invalid version selection."
        pause
        return
    fi

    version_PANEL="${tags[$((version_choice - 1))]}"

    echo ""
    echo -e "  ${CYAN}Selected version:${NC} ${WHITE}${version_PANEL}${NC}"
    echo -ne "  ${RED}Proceed with update? (y/N): ${NC}"
    read -r final_confirm

    if [[ "$final_confirm" != "y" && "$final_confirm" != "Y" ]]; then
        status_msg "INFO" "Update cancelled."
        pause
        return
    fi

    cd /var/www/pterodactyl || {
        status_msg "ERR" "Cannot access panel directory."
        pause
        return
    }

    status_msg "INFO" "Enabling maintenance mode..."
    php artisan down || {
        status_msg "ERR" "Could not enable maintenance mode."
        pause
        return
    }

    status_msg "INFO" "Downloading selected release..."

    if ! curl -fL --retry 3 \
        -o panel.tar.gz \
        "https://github.com/pterodactyl/panel/releases/download/${version_PANEL}/panel.tar.gz"; then
        status_msg "ERR" "Download failed. Panel files were not intentionally cleared."
        rm -f panel.tar.gz
        php artisan up
        pause
        return
    fi

    if ! tar -tzf panel.tar.gz >/dev/null 2>&1; then
        status_msg "ERR" "Downloaded archive is invalid."
        rm -f panel.tar.gz
        php artisan up
        pause
        return
    fi

    echo ""
    status_msg "INFO" "Extracting release over existing panel files..."

    # Note: this does not delete existing files.
    # A tested backup is still strongly recommended.
    if ! tar -xzf panel.tar.gz -C /var/www/pterodactyl; then
        status_msg "ERR" "Extraction failed. Check the panel and restore from backup if needed."
        rm -f panel.tar.gz
        pause
        return
    fi

    rm -f panel.tar.gz

    cd /var/www/pterodactyl || return

    chmod -R 755 storage bootstrap/cache

    status_msg "INFO" "Updating Composer dependencies..."

    if ! COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader; then
        status_msg "ERR" "Composer install failed. Check the panel before bringing it online."
        pause
        return
    fi

    chown -R www-data:www-data /var/www/pterodactyl

    status_msg "INFO" "Clearing caches and running database migrations..."

    php artisan view:clear
    php artisan config:clear

    if ! php artisan migrate --seed --force; then
        status_msg "ERR" "Database migration failed. Panel remains in maintenance mode."
        pause
        return
    fi

    status_msg "INFO" "Restarting queue workers..."

    php artisan queue:restart
    php artisan up

    echo ""
    status_msg "OK" "Update commands completed. Check panel functionality."

    pause
}

# ================================================================
#                         MAIN MENU
# ================================================================

while true; do
    clear

    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo -e "║        ${WHITE}${BOLD}⚡ PTERODACTYL CONTROL CENTER${NC}${PURPLE}                  ║"
    echo -e "║        ${GRAY}Professional Server Management System${NC}${PURPLE}          ║"
    echo "║                                                              ║"
    echo "╠══════════════════════════════════════════════════════════════╣"

    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "║  ${WHITE}${BOLD}PANEL STATUS${NC}${PURPLE} : ${GREEN}${BOLD}INSTALLED ✔${NC}${PURPLE}                       ║"
    else
        echo -e "║  ${WHITE}${BOLD}PANEL STATUS${NC}${PURPLE} : ${RED}${BOLD}NOT INSTALLED ✘${NC}${PURPLE}                   ║"
    fi

    echo -e "║  ${WHITE}${BOLD}CREDITS${NC}${PURPLE}      : ${CYAN}ManzVPS${PURPLE}                                  ║"
    echo "╚══════════════════════════════════════════════════════════════╝"

    echo -e "${NC}"

    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "  ${WHITE}${BOLD}CONTROL MODULES${NC}"
    echo -e "  ${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -e "  ${GREEN}[1]${NC} ${WHITE}${BOLD}Install Panel${NC}"
    echo -e "      ${GRAY}Fresh Pterodactyl Panel Installation${NC}"
    echo ""

    echo -e "  ${GREEN}[2]${NC} ${WHITE}${BOLD}User Management${NC}"
    echo -e "      ${GRAY}Create Admin / User Accounts${NC}"
    echo ""

    echo -e "  ${YELLOW}[3]${NC} ${WHITE}${BOLD}Panel Update${NC}"
    echo -e "      ${GRAY}Update to a Pterodactyl Release${NC}"
    echo ""

    echo -e "  ${RED}[5]${NC} ${WHITE}${BOLD}Uninstall Panel${NC}"
    echo -e "      ${GRAY}Remove Panel Data and Configuration${NC}"
    echo ""

    echo -e "  ${GRAY}──────────────────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}[0]${NC} Exit System"
    echo ""

    echo -ne "  ${CYAN}${BOLD}root@ptero${NC}${GRAY}:~#${NC} "
    read -r choice

    case "$choice" in
        1)
            install_ptero
            ;;
        2)
            create_user
            ;;
        3)
            update_panel
            ;;
        5)
            uninstall_ptero
            ;;
        0)
            clear
            echo ""
            echo -e "${PURPLE}  ╔══════════════════════════════════════════════════════════╗${NC}"
            echo -e "${PURPLE}  ║${NC}                                                      ${PURPLE}║${NC}"
            echo -e "${PURPLE}  ║${NC}       ${GREEN}${BOLD}👋 Thanks for using Pterodactyl CC${NC}          ${PURPLE}║${NC}"
            echo -e "${PURPLE}  ║${NC}                                                      ${PURPLE}║${NC}"
            echo -e "${PURPLE}  ║${NC}       ${GRAY}Credits: ${WHITE}ManzVPS${NC}                           ${PURPLE}║${NC}"
            echo -e "${PURPLE}  ║${NC}                                                      ${PURPLE}║${NC}"
            echo -e "${PURPLE}  ╚══════════════════════════════════════════════════════════╝${NC}"
            echo ""
            exit 0
            ;;
        *)
            echo ""
            echo -e "  ${RED}${BOLD}✖ Invalid option selected.${NC}"
            echo -e "  ${GRAY}Please choose an available option.${NC}"
            sleep 1
            ;;
    esac
done
