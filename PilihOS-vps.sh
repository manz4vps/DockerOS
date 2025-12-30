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

msg1="✨ Make By Manz & Ndaa"
msg2="🐳 Docker Credit by ManzXYZ"
echo -e "\033[1;32m$msg1\033[0m"
sleep 0.5
echo -e "\033[1;34m$msg2\033[0m"
sleep 2
clear

RAW_IDX_URL="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vps-idx.sh"
IDX_FILE="vps-idx-installer.sh"

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} 🧠 VPS IDX Installer"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container"
  echo -e "${YELLOW}6)${RESET} 💻 Jalankan VPS"
  echo -e "${YELLOW}7)${RESET} ❌ Keluar"
  echo
  read -rp "Pilih opsi (1-7): " MENU

  case "$MENU" in
    1)
      clear
      echo -e "${BOLD}${CYAN}🧰 Pilih OS yang mau dijalankan:${RESET}"
      echo -e "${YELLOW}1)${RESET} Debian 11"
      echo -e "${YELLOW}2)${RESET} Debian 12"
      echo -e "${YELLOW}3)${RESET} Ubuntu 22"
      echo -e "${YELLOW}4)${RESET} Ubuntu 24"
      echo -e "${YELLOW}5)${RESET} 🔙 Kembali"
      read -rp "Masukkan pilihan (1-5): " OS_CHOICE

      case "$OS_CHOICE" in
        1) IMAGE_NAME="manz4vps/debian11"; CONTAINER_NAME="debian11" ;;
        2) IMAGE_NAME="manz4vps/debian12"; CONTAINER_NAME="debian12" ;;
        3) IMAGE_NAME="manz4vps/ubuntu22"; CONTAINER_NAME="ubuntu22" ;;
        4) IMAGE_NAME="manz4vps/ubuntu24"; CONTAINER_NAME="ubuntu24" ;;
        5) clear; continue ;;
        *) echo -e "${RED}❌ Pilihan tidak valid!${RESET}"; continue ;;
      esac

      echo -e "${BOLD}${CYAN}⚙️  Masukkan konfigurasi resource:${RESET}"
      read -rp "🧠 RAM (contoh 5G): " RAM
      read -rp "🧩 CPU (contoh 2): " CPU
      read -rp "💾 Disk (contoh 20G): " DISK_SIZE

      RAM=$(echo "$RAM" | tr '[:upper:]' '[:lower:]')
      DISK_SIZE=$(echo "$DISK_SIZE" | tr '[:upper:]' '[:lower:]')

      VMDATA_DIR="$PWD/vmdata"
      mkdir -p "$VMDATA_DIR"
      FILE_NAME="${CONTAINER_NAME}.sh"

      cat > "$FILE_NAME" <<EOF
#!/bin/bash
docker run -it --rm \\
  --name "$CONTAINER_NAME" \\
  --device /dev/kvm \\
  -v "$VMDATA_DIR":/vmdata \\
  -e RAM="$RAM" \\
  -e CPU="$CPU" \\
  -e DISK_SIZE="$DISK_SIZE" \\
  "$IMAGE_NAME"
EOF

      chmod +x "$FILE_NAME"
      echo -e "${GREEN}✅ File ${FILE_NAME} berhasil dibuat!${RESET}"
      read -rp "🚀 Jalankan sekarang? (y/n): " RUN_NOW
      [[ "$RUN_NOW" =~ ^[Yy]$ ]] && bash "$FILE_NAME"
      ;;

    2)
      clear
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
      read -rp "Tekan [Enter] untuk kembali..." ;;

    3)
      clear
      echo -e "${CYAN}🧠 Mengunduh VPS IDX Installer...${RESET}"
      curl -fsSL "$RAW_IDX_URL" -o "$IDX_FILE" || {
        echo -e "${RED}❌ Gagal download script IDX!${RESET}"
        read -rp "Tekan [Enter]..."
        continue
      }
      chmod +x "$IDX_FILE"
      echo -e "${GREEN}✅ VPS IDX Installer siap dijalankan${RESET}"
      read -rp "🚀 Jalankan sekarang? (y/n): " RUN_IDX
      [[ "$RUN_IDX" =~ ^[Yy]$ ]] && bash "$IDX_FILE"
      ;;

    4)
      clear
      docker ps --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container (0 kembali): " STOP_NAME
      [[ "$STOP_NAME" == "0" ]] && continue
      docker stop "$STOP_NAME"
      read -rp "Tekan [Enter]..." ;;

    5)
      clear
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container (0 kembali): " RM_NAME
      [[ "$RM_NAME" == "0" ]] && continue
      docker rm -f "$RM_NAME"
      read -rp "Tekan [Enter]..." ;;

    6)
      clear
      ls -1 *.sh 2>/dev/null || echo "Belum ada file .sh"
      read -rp "Nama file (0 kembali): " SCRIPT_NAME
      [[ "$SCRIPT_NAME" == "0" ]] && continue
      bash "$SCRIPT_NAME"
      ;;

    7)
      echo -e "${GREEN}👋 Keluar dari script. Sampai jumpa bro!${RESET}"
      exit 0
      ;;

    *)
      echo -e "${RED}❌ Pilihan tidak valid!${RESET}"
      read -rp "Tekan [Enter]..." ;;
  esac

  clear
done
