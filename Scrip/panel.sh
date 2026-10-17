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
    case "$1" in
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

# Read input directly from the controlling terminal.
# This prevents EOF/piped stdin from silently choosing a default.
read_tty() {
    local result
    local prompt="${2:-}"

    if [[ ! -r /dev/tty ]]; then
        printf '\n'
        status_msg "ERR" "Interactive terminal unavailable."
        return 1
    fi

    printf '%s' "$prompt" > /dev/tty

    if ! IFS= read -r result < /dev/tty; then
        return 1
    fi

    printf -v "$1" '%s' "$result"
    return 0
}

pause() {
    local pause_input

    echo ""
    read_tty pause_input "  ${GRAY}Press [Enter] to return to main menu...${NC}" || true
    echo ""
}

confirm_yes() {
    local answer
    local prompt="$1"

    while true; do
        if ! read_tty answer "$prompt"; then
            return 1
        fi

        case "${answer,,}" in
            y|yes)
                return 0
                ;;
            n|no|"")
                return 1
                ;;
            *)
                status_msg "ERR" "Please enter y or n, then press Enter."
                ;;
        esac
    done
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

    local installer_tmp
    installer_tmp="$(mktemp)" || {
        status_msg "ERR" "Could not create a temporary file."
        pause
        return
    }

    if ! curl -fsSL \
        "https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-panel.sh" \
        -o "$installer_tmp"; then
        status_msg "ERR" "Failed to download installation script."
        rm -f "$installer_tmp"
        pause
        return
    fi

    bash "$installer_tmp"
    local installer_status=$?

    rm -f "$installer_tmp"

    echo ""
    if (( installer_status == 0 )); then
        status_msg "OK" "Installation script finished."
    else
        status_msg "ERR" "Installer exited with status ${installer_status}."
        status_msg "INFO" "Check the installer output for errors."
    fi

    pause
}

# ================================================================
#                       USER MANAGEMENT
# ================================================================

create_user() {
    show_header "USER MANAGEMENT"

    if [[ ! -d /var/www/pterodactyl ]]; then
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

    local choice
    if ! read_tty choice "  ${CYAN}${BOLD}root@ptero${NC}${GRAY}:~#${NC} "; then
        status_msg "ERR" "Could not read your selection."
        pause
        return
    fi

    cd /var/www/pterodactyl || {
        status_msg "ERR" "Cannot access panel directory."
        pause
        return
    }

    if [[ "$choice" == "1" ]]; then
        show_header "USER MANAGEMENT"

        status_msg "WAIT" "Launching manual user creation..."
        php artisan p:user:make

    elif [[ "$choice" == "2" ]]; then
        show_header "USER MANAGEMENT"

        status_msg "WAIT" "Creating auto admin user..."

        local USERNAME PASSWORD EMAIL FIRST LAST

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

        local user_status=$?

        echo ""

        if (( user_status == 0 )); then
            section "GENERATED CREDENTIALS"

            echo -e "  ${CYAN}Username${NC} : ${WHITE}$USERNAME${NC}"
            echo -e "  ${CYAN}Password${NC} : ${WHITE}$PASSWORD${NC}"
            echo -e "  ${CYAN}Email${NC}    : ${WHITE}$EMAIL${NC}"

            section_end
        else
            status_msg "ERR" "User creation command failed."
        fi

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

    local confirm

    if ! confirm_yes "  ${RED}${BOLD}Are you sure? (y/N):${NC} "; then
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

# Global list used by the version selector.
PANEL_TAGS=()

fetch_github_versions() {
    local repo="$1"
    local json

    if ! command -v python3 >/dev/null 2>&1; then
        status_msg "ERR" "python3 is required to parse GitHub releases."
        return 1
    fi

    json="$(curl -fsSL --retry 2 \
        "https://api.github.com/repos/${repo}/releases?per_page=20")" || {
        status_msg "ERR" "Failed to fetch releases from GitHub."
        return 1
    }

    python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception as exc:
    print("Failed to parse GitHub response: " + str(exc), file=sys.stderr)
    sys.exit(1)

if not isinstance(data, list):
    print("Unexpected GitHub API response.", file=sys.stderr)
    sys.exit(1)

for release in data:
    if not isinstance(release, dict):
        continue
    if release.get("prerelease", False):
        continue

    tag = release.get("tag_name", "")
    if isinstance(tag, str) and tag.startswith("v"):
        print(tag)
' <<< "$json"
}

select_panel_version() {
    local total="${#PANEL_TAGS[@]}"
    local index=0
    local action
    local version

    if (( total == 0 )); then
        status_msg "ERR" "No versions available."
        return 1
    fi

    while true; do
        show_header "PANEL VERSION SELECTOR"

        echo -e "  ${WHITE}${BOLD}Choose a Pterodactyl Panel release${NC}"
        echo ""
        echo -e "  ${GRAY}Version ${index+1} of ${total}${NC}"
        echo ""
        echo -e "  ${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
        printf "  ${PURPLE}║${NC}  ${GREEN}${BOLD}%-56s${NC}${PURPLE}║${NC}\n" "${PANEL_TAGS[$index]}"
        echo -e "  ${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
        echo ""

        if (( index == 0 )); then
            echo -e "  ${GRAY}[P] Previous  (already at the first version)${NC}"
        else
            echo -e "  ${CYAN}[P]${NC} Previous version"
        fi

        if (( index >= total - 1 )); then
            echo -e "  ${GRAY}[N] Next      (already at the last version)${NC}"
        else
            echo -e "  ${CYAN}[N]${NC} Next version"
        fi

        echo -e "  ${GREEN}[S]${NC} Select this version"
        echo -e "  ${RED}[0]${NC} Cancel"
        echo ""

        if ! read_tty action "  ${CYAN}Choose [P/N/S/0]: ${NC}"; then
            status_msg "ERR" "Could not read selection."
            return 1
        fi

        case "${action,,}" in
            p|previous)
                if (( index > 0 )); then
                    ((index--))
                else
                    status_msg "INFO" "You are already at the first version."
                    sleep 1
                fi
                ;;

            n|next)
                if (( index < total - 1 )); then
                    ((index++))
                else
                    status_msg "INFO" "You are already at the latest version in this list."
                    sleep 1
                fi
                ;;

            s|select)
                version="${PANEL_TAGS[$index]}"
                printf '%s\n' "$version"
                return 0
                ;;

            0|q|quit|cancel)
                return 1
                ;;

            "")
                status_msg "ERR" "No selection entered. Type P, N, S, or 0."
                sleep 1
                ;;

            *)
                status_msg "ERR" "Invalid selection. Use P, N, S, or 0."
                sleep 1
                ;;
        esac
    done
}

update_panel() {
    show_header "SYSTEM UPDATE"

    if [[ ! -d /var/www/pterodactyl ]]; then
        status_msg "ERR" "Panel not found in /var/www/pterodactyl."
        pause
        return
    fi

    echo -e "  ${RED}${BOLD}WARNING:${NC} Updating can replace panel files."
    echo -e "  ${YELLOW}Back up panel files and database before proceeding.${NC}"
    echo ""

    if ! confirm_yes "  ${CYAN}Continue with update? (y/N): ${NC}"; then
        status_msg "INFO" "Update cancelled."
        pause
        return
    fi

    local GITHUB_REPO="pterodactyl/panel"
    local version_PANEL
    local selected_version
    local selection_output
    local update_status

    PANEL_TAGS=()

    status_msg "WAIT" "Fetching releases from GitHub..."

    # Collect versions without mixing status messages into the version list.
    local releases_output
    if ! releases_output="$(fetch_github_versions "$GITHUB_REPO")"; then
        status_msg "ERR" "Could not retrieve release versions."
        pause
        return
    fi

    while IFS= read -r tag; do
        [[ -n "$tag" ]] && PANEL_TAGS+=("$tag")
    done <<< "$releases_output"

    if (( ${#PANEL_TAGS[@]} == 0 )); then
        status_msg "ERR" "No stable releases found. Update cancelled."
        pause
        return
    fi

    # Capture selector output while preserving interactive input via /dev/tty.
    if ! selected_version="$(select_panel_version)"; then
        status_msg "INFO" "Version selection cancelled."
        pause
        return
    fi

    version_PANEL="$selected_version"

    echo ""
    echo -e "  ${CYAN}Selected version:${NC} ${WHITE}${version_PANEL}${NC}"
    echo ""

    if ! confirm_yes "  ${RED}Proceed with update to ${version_PANEL}? (y/N): ${NC}"; then
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

    if ! php artisan down; then
        status_msg "ERR" "Could not enable maintenance mode."
        pause
        return
    fi

    status_msg "INFO" "Downloading selected release..."

    if ! curl -fL --retry 3 \
        -o panel.tar.gz \
        "https://github.com/pterodactyl/panel/releases/download/${version_PANEL}/panel.tar.gz"; then
        status_msg "ERR" "Download failed."
        rm -f panel.tar.gz
        status_msg "INFO" "Attempting to disable maintenance mode..."
        php artisan up || true
        pause
        return
    fi

    if ! tar -tzf panel.tar.gz >/dev/null 2>&1; then
        status_msg "ERR" "Downloaded archive is invalid."
        rm -f panel.tar.gz
        php artisan up || true
        pause
        return
    fi

    echo ""
    status_msg "INFO" "Extracting release over existing panel files..."

    # This overlays files and does not remove obsolete files.
    # A verified backup is strongly recommended before updating.
    if ! tar -xzf panel.tar.gz -C /var/www/pterodactyl; then
        status_msg "ERR" "Extraction failed. Panel may be partially updated."
        rm -f panel.tar.gz
        status_msg "ERR" "Leaving maintenance mode enabled for safety."
        pause
        return
    fi

    rm -f panel.tar.gz

    cd /var/www/pterodactyl || {
        status_msg "ERR" "Cannot access panel directory after extraction."
        pause
        return
    }

    chmod -R 755 storage bootstrap/cache

    status_msg "INFO" "Updating Composer dependencies..."

    if ! COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader; then
        status_msg "ERR" "Composer install failed."
        status_msg "ERR" "Leaving maintenance mode enabled for safety."
        pause
        return
    fi

    chown -R www-data:www-data /var/www/pterodactyl

    status_msg "INFO" "Clearing caches..."

    if ! php artisan view:clear; then
        status_msg "ERR" "Could not clear view cache."
        pause
        return
    fi

    if ! php artisan config:clear; then
        status_msg "ERR" "Could not clear config cache."
        pause
        return
    fi

    status_msg "INFO" "Running database migrations..."

    if ! php artisan migrate --seed --force; then
        status_msg "ERR" "Database migration failed."
        status_msg "ERR" "Leaving maintenance mode enabled for safety."
        pause
        return
    fi

    status_msg "INFO" "Restarting queue workers..."

    php artisan queue:restart || true

    if ! php artisan up; then
        status_msg "ERR" "Could not disable maintenance mode."
        pause
        return
    fi

    echo ""
    status_msg "OK" "Update commands completed."
    status_msg "INFO" "Check panel functionality and logs."

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

    if [[ -d "/var/www/pterodactyl" ]]; then
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

    local_choice=""

    if ! read_tty local_choice "  ${CYAN}${BOLD}root@ptero${NC}${GRAY}:~#${NC} "; then
        echo ""
        status_msg "ERR" "Unable to read input from terminal."
        sleep 2
        continue
    fi

    case "$local_choice" in
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
