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

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 💻 Buat VPS QEMU x86"
  echo -e "${YELLOW}2)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}3)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container"
  echo -e "${YELLOW}6)${RESET} 💻 Jalankan VPS"
  echo -e "${YELLOW}7)${RESET} ❌ Keluar"
  echo
  read -rp "Pilih opsi (1-7): " MENU

  case "$MENU" in
    1)
      clear
      echo -e "${CYAN}🧠 Membuat VPS QEMU x86...${RESET}"
      read -rp "Masukkan nama file VPS (contoh: qemu-x86.sh): " FILE_NAME
      FILE_NAME="${FILE_NAME:-qemu-x86.sh}"

      RAW_URL="https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vps-qemu-x86"

      echo -e "${GREEN}📥 Mengunduh script QEMU dari GitHub...${RESET}"
      curl -fsSL "$RAW_URL" -o "$FILE_NAME" || {
        echo -e "${RED}❌ Gagal mengunduh script dari GitHub!${RESET}"
        read -rp "Tekan [Enter] untuk kembali..."
        continue
      }

      chmod +x "$FILE_NAME"
      echo -e "${GREEN}✅ File ${FILE_NAME} berhasil diunduh & disiapkan!${RESET}"
      echo -e "📂 Lokasi: ${CYAN}$PWD/${FILE_NAME}${RESET}"
      echo

      read -rp "🚀 Mau langsung jalankan sekarang? (y/n): " RUN_NOW
      if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Menjalankan VPS QEMU...${RESET}"
        sleep 1
        bash "$FILE_NAME"
      else
        echo -e "${YELLOW}📁 File tersimpan. Jalankan nanti dengan: ${CYAN}bash ${FILE_NAME}${RESET}"
      fi
      ;;

    2)
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

      # Buat file .sh
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
      echo
      echo -e "${GREEN}✅ File ${FILE_NAME} berhasil dibuat!${RESET}"
      echo -e "📂 Disimpan di: ${CYAN}$PWD/${FILE_NAME}${RESET}"
      echo

      read -rp "🚀 Mau langsung jalankan VPS sekarang? (y/n): " RUN_NOW
      if [[ "$RUN_NOW" =~ ^[Yy]$ ]]; then
        echo -e "${GREEN}Menjalankan VPS ${CONTAINER_NAME}...${RESET}"
        sleep 1
        bash "$FILE_NAME"
      else
        echo -e "${YELLOW}📁 File tersimpan. Jalankan nanti dengan: ${CYAN}bash ${FILE_NAME}${RESET}"
      fi
      ;;

    3)
      clear
      echo -e "${CYAN}🔍 Daftar container aktif:${RESET}"
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
      echo
      read -rp "Tekan [Enter] untuk kembali..." ;;
      
    4)
      clear
      docker ps --format "table {{.Names}}\t{{.Status}}"
      echo
      read -rp "Masukkan nama container yang mau di-stop (atau 0 untuk kembali): " STOP_NAME
      [[ "$STOP_NAME" == "0" ]] && continue
      docker stop "$STOP_NAME" && echo -e "${YELLOW}⏹️  Container $STOP_NAME dihentikan.${RESET}"
      echo
      read -rp "Tekan [Enter] untuk kembali..." ;;
      
    5)
      clear
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      echo
      read -rp "Masukkan nama container yang mau dihapus (atau 0 untuk kembali): " RM_NAME
      [[ "$RM_NAME" == "0" ]] && continue
      docker rm -f "$RM_NAME" && echo -e "${RED}🗑️  Container $RM_NAME dihapus.${RESET}"
      echo
      read -rp "Tekan [Enter] untuk kembali..." ;;
      
    6)
      clear
      echo -e "${CYAN}💻 Daftar file container (.sh) yang tersedia:${RESET}"
      ls -1 *.sh 2>/dev/null || echo "Belum ada file .sh"
      echo
      read -rp "Masukkan nama file (contoh: debian11.sh) atau 0 untuk kembali: " SCRIPT_NAME
      [[ "$SCRIPT_NAME" == "0" ]] && continue

      if [ ! -f "$SCRIPT_NAME" ]; then
        echo -e "${RED}❌ File $SCRIPT_NAME tidak ditemukan!${RESET}"
        read -rp "Tekan [Enter] untuk kembali..."
        continue
      fi

      echo -e "${GREEN}🚀 Menjalankan file ${SCRIPT_NAME}...${RESET}"
      sleep 1
      bash "$SCRIPT_NAME"
      ;;

    7)
      echo -e "${GREEN}👋 Keluar dari script. Sampai jumpa bro!${RESET}"
      exit 0
      ;;

    *)
      echo -e "${RED}❌ Pilihan tidak valid!${RESET}"
      read -rp "Tekan [Enter] untuk kembali..." ;;
  esac

  clear
done
