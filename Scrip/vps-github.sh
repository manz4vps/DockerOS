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

# Fungsi untuk menghapus container & data
hapus_container() {
    local container_name=$1
    local file_script="$container_name.sh"
    local data_dir="vmdata_$container_name"

    echo -e "${YELLOW}➤ Memproses penghapusan: $container_name${RESET}"

    # 1. Stop & Hapus Container Docker
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        docker rm -f "$container_name" >/dev/null 2>&1
        echo -e "   - Container Docker: ${GREEN}Terhapus${RESET}"
    else
        echo -e "   - Container Docker: ${RED}Tidak ditemukan${RESET}"
    fi

    # 2. Hapus File Script (.sh)
    if [ -f "$file_script" ]; then
        rm "$file_script"
        echo -e "   - File Script ($file_script): ${GREEN}Terhapus${RESET}"
    else
        echo -e "   - File Script: ${RED}Tidak ditemukan${RESET}"
    fi

    # 3. Hapus Folder Data
    if [ -d "$data_dir" ]; then
        rm -rf "$data_dir"
        echo -e "   - Folder Data ($data_dir): ${GREEN}Terhapus${RESET}"
    else
        echo -e "   - Folder Data: ${RED}Tidak ditemukan${RESET}"
    fi

    # 4. Bersihkan entry di .bashrc (menghapus baris yang mengandung nama container/file)
    # Ini menghapus baris spesifik logic auto start
    if grep -q "$container_name" ~/.bashrc; then
         # Backup dulu jaga-jaga
         cp ~/.bashrc ~/.bashrc.bak
         # Hapus blok logic (agak tricky, jadi kita hapus baris yang mengandung nama container tsb)
         sed -i "/$container_name/d" ~/.bashrc
         echo -e "   - Config .bashrc: ${GREEN}Dibersihkan${RESET}"
    fi
    echo ""
}

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
  echo -e "${YELLOW}4)${RESET} 🗑️ Hapus Container (Pilih / Semua)"
  echo -e "${YELLOW}5)${RESET} 💻 Jalankan VPS Manual"
  echo -e "${YELLOW}6)${RESET} 🔄 Pasang Auto Start (.bashrc)"
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

      # Folder data spesifik
      DATA_DIR="vmdata_$NAME"
      mkdir -p "$DATA_DIR"
      
      FILE="$NAME.sh"

      cat > "$FILE" <<EOF
#!/bin/bash
docker run -it --rm \\
  --name "$NAME" \\
  --device /dev/kvm \\
  -v "\$PWD/$DATA_DIR":/vmdata \\
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
      echo -e "${BOLD}${RED}🗑️  HAPUS CONTAINER & DATA${RESET}"
      
      # Ambil list file .sh
      files=(*.sh)
      
      # Cek jika tidak ada file
      if [ ! -e "${files[0]}" ]; then
          echo -e "${RED}Tidak ada file script (.sh) ditemukan!${RESET}"
          read -rp "Enter untuk kembali..."
          continue
      fi

      echo "Daftar Container Tersedia:"
      i=1
      for file in "${files[@]}"; do
          echo -e "${YELLOW}$i)${RESET} $file"
          ((i++))
      done
      
      echo -e "${RED}88) 💥 HAPUS SEMUA (DELETE ALL)${RESET}"
      echo -e "${CYAN}0)  🔙 Kembali${RESET}"
      
      echo ""
      read -rp "Pilih Nomor: " DEL_OPT
      
      # Logic Hapus
      if [ "$DEL_OPT" -eq 0 ]; then
          continue
      elif [ "$DEL_OPT" -eq 88 ]; then
          echo -e "\n${BOLD}${RED}⚠️  PERINGATAN KERAS! ⚠️${RESET}"
          echo -e "Anda akan menghapus ${BOLD}SEMUA${RESET} container, script, dan data yang ada di list."
          read -rp "Apakah anda yakin? (y/n): " SURE
          if [[ "$SURE" == "y" || "$SURE" == "Y" ]]; then
              for file in "${files[@]}"; do
                  C_NAME=$(basename "$file" .sh)
                  hapus_container "$C_NAME"
              done
              echo -e "${BOLD}Selesai! Semua bersih.${RESET}"
          else
              echo "Dibatalkan."
          fi
      elif [[ "$DEL_OPT" =~ ^[0-9]+$ ]] && [ "$DEL_OPT" -ge 1 ] && [ "$DEL_OPT" -le "${#files[@]}" ]; then
          TARGET_FILE="${files[$((DEL_OPT-1))]}"
          C_NAME=$(basename "$TARGET_FILE" .sh)
          
          read -rp "Hapus $C_NAME beserta datanya? (y/n): " SURE
          if [[ "$SURE" == "y" || "$SURE" == "Y" ]]; then
              hapus_container "$C_NAME"
              echo -e "${BOLD}Penghapusan selesai.${RESET}"
          else
              echo "Dibatalkan."
          fi
      else
          echo -e "${RED}Pilihan tidak valid!${RESET}"
      fi
      read -rp "Enter untuk kembali..."
      ;;

    5)
      clear
      ls *.sh 2>/dev/null || echo "Tidak ada file"
      read -rp "Nama file: " F
      bash "$F"
      ;;

    6)
      clear
      echo -e "${BOLD}${CYAN}🔄 Setup Auto Start VPS (.bashrc)${RESET}"
      
      files=(*.sh)
      if [ ! -e "${files[0]}" ]; then
          echo -e "${RED}Tidak ada file script (.sh) ditemukan!${RESET}"
          read -rp "Enter untuk kembali..."
          continue
      fi

      echo "Pilih Container untuk Auto Start:"
      i=1
      for file in "${files[@]}"; do
          echo -e "${YELLOW}$i)${RESET} $file"
          ((i++))
      done
      
      echo ""
      read -rp "Pilih Nomor: " NUM
      
      if [[ "$NUM" =~ ^[0-9]+$ ]] && [ "$NUM" -ge 1 ] && [ "$NUM" -le "${#files[@]}" ]; then
          START_FILE="${files[$((NUM-1))]}"
          CONTAINER_NAME=$(basename "$START_FILE" .sh)
          
          if grep -q "PENGATURAN AUTO START VPS" ~/.bashrc; then
              echo -e "${YELLOW}Settingan autostart sudah ada. Hapus manual dulu atau gunakan Menu 4 (Hapus) untuk reset.${RESET}"
          else
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
              echo -e "${GREEN}Sukses!${RESET} Auto Start aktif untuk $CONTAINER_NAME."
          fi
      else
          echo -e "${RED}Nomor tidak valid!${RESET}"
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
