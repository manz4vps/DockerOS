#!/bin/bash

# ==========================================
#        MODERN VPS INSTALLER PANEL
#           PURE BASH VERSION
# ==========================================

# ANSI COLORS
R='\033[0;31m'
G='\033[0;32m'
Y='\033[0;33m'
B='\033[0;34m'
M='\033[0;35m'
C='\033[0;36m'
W='\033[1;37m'
D='\033[0;90m'
NC='\033[0m'

# Installer URLs
URL1="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vps-installer.sh"
URL2="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/windows-installer.sh"
URL3="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/all-autoinstaller.sh"

# ==========================================
# COLORFUL HEADER
# ==========================================

header() {
    clear

    echo -e "${C}"
    echo "╔══════════════════════════════════════════════╗"
    echo "║                                              ║"
    echo "║          M O D E R N   V P S                 ║"
    echo "║             I N S T A L L E R                ║"
    echo "║                                              ║"
    echo "╚══════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${D}           VPS MANAGEMENT PANEL${NC}"
    echo
}

# ==========================================
# MENU DISPLAY
# ==========================================

menu() {
    echo -e "${B}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${B}│${NC}              ${W}SELECT INSTALLER${NC}                 ${B}│${NC}"
    echo -e "${B}├──────────────────────────────────────────────┤${NC}"
    echo -e "${B}│${NC}                                              ${B}│${NC}"
    echo -e "${B}│${NC}  ${G}[1]${NC}  VPS Installer                         ${B}│${NC}"
    echo -e "${B}│${NC}  ${C}[2]${NC}  Windows Installer                     ${B}│${NC}"
    echo -e "${B}│${NC}  ${M}[3]${NC}  All Auto Installer                    ${B}│${NC}"
    echo -e "${B}│${NC}                                              ${B}│${NC}"
    echo -e "${B}├──────────────────────────────────────────────┤${NC}"
    echo -e "${B}│${NC}  ${R}[0]${NC}  Exit                                  ${B}│${NC}"
    echo -e "${B}└──────────────────────────────────────────────┘${NC}"
    echo
}

# ==========================================
# RUN INSTALLER
# ==========================================

run_installer() {
    local name="$1"
    local url="$2"

    echo
    echo -e "${C}┌──────────────────────────────────────────────┐${NC}"
    echo -e "${C}│${NC}           ${W}INSTALLER CONFIRMATION${NC}              ${C}│${NC}"
    echo -e "${C}└──────────────────────────────────────────────┘${NC}"
    echo
    echo -e " ${Y}Selected:${NC} ${W}$name${NC}"
    echo

    read -rp "$(echo -e "${G} Run installer? [y/N]: ${NC}")" confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then

        echo
        echo -e "${C} Downloading installer...${NC}"

        local tmp
        tmp=$(mktemp) || {
            echo -e "${R}Unable to create temporary file.${NC}"
            read -rp "Press Enter to continue..."
            return
        }

        if curl -fsSL "$url" -o "$tmp"; then

            echo -e "${G} Download successful.${NC}"
            echo

            # Execute downloaded installer
            bash "$tmp"

            rm -f "$tmp"

        else

            echo -e "${R} Download failed!${NC}"
            rm -f "$tmp"

        fi

    else
        echo
        echo -e "${Y} Installation cancelled.${NC}"
    fi

    echo
    read -rp "$(echo -e "${D} Press Enter to return to menu... ${NC}")"
}

# ==========================================
# MAIN LOOP
# ==========================================

while true; do

    header
    menu

    read -rp "$(echo -e "${C} Select Option ${W}> ${NC}")" choice

    case "$choice" in

        1)
            run_installer "VPS Installer" "$URL1"
            ;;

        2)
            run_installer "Windows Installer" "$URL2"
            ;;

        3)
            run_installer "All Auto Installer" "$URL3"
            ;;

        0)
            clear
            echo
            echo -e "${G} Thank you for using Modern VPS Installer!${NC}"
            echo
            exit 0
            ;;

        *)
            echo
            echo -e "${R} Invalid option! Please select 0-3.${NC}"
            sleep 2
            ;;
    esac

done
