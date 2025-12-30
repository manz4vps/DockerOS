#!/bin/bash
set -euo pipefail
clear

# Warna
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"
BOLD="\e[1m"

# Banner
cat << "EOF"
██████╗   ██╗   ███████╗  ███╗   ███╗   █████╗   ███╗   ██╗
██╔══██╗  ██║   ██╔════╝  ████╗ ████║  ██╔══██╗  ████╗  ██║
██████╔╝  ██║   ███████╗  ██╔████╔██║  ███████║  ██╔██╗ ██║
██╔══██╗  ██║   ╚════██║  ██║╚██╔╝██║  ██╔══██║  ██║╚██╗██║
██║  ██║  ██║   ███████║  ██║ ╚═╝ ██║  ██║  ██║  ██║ ╚████║
╚═╝  ╚═╝  ╚═╝   ╚══════╝  ╚═╝     ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚═══╝
EOF
sleep 1
clear

echo -e "\033[1;32m✨ Make By Manz & Ndaa\033[0m"
sleep 0.5
echo -e "\033[1;34m🐳 Docker Credit by ManzXYZ\033[0m"
sleep 2
clear

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} 🧠 VPS IDX Installer (AUTO RUN)"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container"
  echo -e "${YELLOW}6)${RESET} 💻 Jalankan VPS"
  echo -e "${YELLOW}7)${RESET} ❌ Keluar"
  echo
  read -rp "Pilih opsi (1-7): " MENU

  case "$MENU" in
    1)
      clear
      echo -e "${BOLD}${CYAN}🧰 Pilih OS:${RESET}"
      echo -e "1) Debian 11"
      echo -e "2) Debian 12"
      echo -e "3) Ubuntu 22"
      echo -e "4) Ubuntu 24"
      echo -e "5) Kembali"
      read -rp "Pilih: " OS

      case "$OS" in
        1) IMAGE="manz4vps/debian11"; NAME="debian11" ;;
        2) IMAGE="manz4vps/debian12"; NAME="debian12" ;;
        3) IMAGE="manz4vps/ubuntu22"; NAME="ubuntu22" ;;
        4) IMAGE="manz4vps/ubuntu24"; NAME="ubuntu24" ;;
        5) continue ;;
        *) echo "Invalid"; sleep 1; continue ;;
      esac

      read -rp "RAM (contoh 5G): " RAM
      read -rp "CPU (contoh 2): " CPU
      read -rp "Disk (contoh 20G): " DISK

      mkdir -p vmdata
      FILE="$NAME.sh"

      cat > "$FILE" <<EOF
#!/bin/bash
docker run -it --rm \\
  --name "$NAME" \\
  --device /dev/kvm \\
  -v "\$PWD/vmdata":/vmdata \\
  -e RAM="$RAM" \\
  -e CPU="$CPU" \\
  -e DISK_SIZE="$DISK" \\
  "$IMAGE"
EOF

      chmod +x "$FILE"
      bash "$FILE"
      ;;

    2)
      clear
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
      read -rp "Enter..." ;;

    3)
      clear
      echo -e "${CYAN}🚀 Menjalankan VPS IDX Installer...${RESET}"
      bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vps-idx.sh)
      read -rp "Tekan [Enter] untuk kembali..."
      ;;

    4)
      clear
      docker ps --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      docker stop "$C"
      ;;

    5)
      clear
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      docker rm -f "$C"
      ;;

    6)
      clear
      ls *.sh 2>/dev/null || echo "Tidak ada file"
      read -rp "Nama file: " F
      bash "$F"
      ;;

    7)
      echo -e "${GREEN}Keluar...${RESET}"
      exit 0
      ;;
  esac
  clear
done
