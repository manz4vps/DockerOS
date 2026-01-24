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
sleep 0.7
clear

echo -e "\033[1;32m✨ Make By Manz & Ndaa\033[0m"
sleep 0.6
echo -e "\033[1;34m🐳 Docker Credit by ManzXYZ\033[0m"
sleep 0.5
clear

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} ⏹️ Stop Container"
  echo -e "${YELLOW}4)${RESET} 🗑️ Hapus Container"
  echo -e "${YELLOW}5)${RESET} 💻 Jalankan VPS Manual"
  echo -e "${YELLOW}6)${RESET} 🔄 Pasang Auto Start (.bashrc) [REVISI]"
  echo -e "${YELLOW}0)${RESET} ❌ Keluar"
  echo
  read -rp "Pilih opsi (0-6): " MENU

  case "$MENU" in
    1)
      clear
      echo -e "${BOLD}${CYAN}🧰 Pilih OS:${RESET}"
      echo -e "1) Debian 11"
      echo -e "2) Debian 12"
      echo -e "3) Ubuntu 22"
      echo -e "4) Ubuntu 24"
      echo -e "0) Kembali"
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

      # Membuat script launcher
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
      docker ps --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      docker stop "$C"
      ;;

    4)
      clear
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      docker rm -f "$C"
      ;;

    5)
      clear
      ls *.sh 2>/dev/null || echo "Tidak ada file"
      read -rp "Nama file: " F
      bash "$F"
      ;;

    6)
      clear
      echo -e "${BOLD}${CYAN}🔄 Setup Auto Start VPS${RESET}"
      echo -e "List file yang tersedia:"
      ls *.sh 2>/dev/null
      
      if [ $? -ne 0 ]; then
          echo -e "${RED}Tidak ada file script (.sh) ditemukan!${RESET}"
          read -rp "Enter untuk kembali..."
          continue
      fi
      
      echo ""
      read -rp "Masukkan nama file (contoh: debian11.sh): " START_FILE

      if [ -f "$START_FILE" ]; then
          # Ambil nama container dari nama file (hilangkan .sh)
          CONTAINER_NAME=$(basename "$START_FILE" .sh)
          
          # Cek duplikat di bashrc
          if grep -q "PENGATURAN AUTO START VPS" ~/.bashrc; then
              echo -e "${YELLOW}Settingan sudah ada di .bashrc. Hapus manual dulu jika ingin ganti.${RESET}"
          else
              # Inject Logic ke .bashrc
              cat <<EOF >> ~/.bashrc

# === PENGATURAN AUTO START VPS ===
# Cek apakah container $CONTAINER_NAME sudah jalan
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "\033[1;33m⚠️  Container ${CONTAINER_NAME} sedang berjalan!\033[0m"
    read -rp "Matikan container dan masuk ulang? (y/n): " YN
    if [[ "\$YN" == "y" || "\$YN" == "Y" ]]; then
        echo -e "\033[1;31m⏹️  Mematikan container...\033[0m"
        docker stop ${CONTAINER_NAME}
        echo -e "\033[1;32m🚀 Memulai ulang...\033[0m"
        bash ./${START_FILE}
    else
        echo "Oke, tetap di terminal host."
    fi
else
    # Jika container mati, langsung jalankan
    bash ./${START_FILE}
fi
# =================================
EOF
              
              echo -e "${GREEN}Sukses!${RESET} Auto Start telah dipasang."
              echo -e "Sekarang, setiap login akan dicek apakah mau masuk container atau tidak."
          fi
      else
          echo -e "${RED}File '$START_FILE' tidak ditemukan.${RESET}"
      fi
      read -rp "Enter untuk kembali..." 
      ;;

    0)
      clear
      echo -e "${GREEN}Keluar...${RESET}"
      exit 0
      ;;
      
    *)
      echo -e "${RED}Pilihan tidak valid!${RESET}"
      sleep 1
      ;;
  esac
  clear
done
