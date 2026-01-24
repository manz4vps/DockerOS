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

# --- KONFIGURASI PENYIMPANAN PINTAR ---
# Ambil lokasi file script ini berada (Absolute Path)
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")

# Tentukan lokasi penyimpanan (Naik 1 level dari folder script, lalu ke folder 'vms')
# Contoh: Jika script di /workspaces/repo, maka data ada di /workspaces/vms
RAW_STORAGE_DIR="$SCRIPT_DIR/../vms"

# Buat folder vms jika belum ada
mkdir -p "$RAW_STORAGE_DIR/vmdata"

# Ubah jadi Absolute Path biar Docker & System ga bingung
STORAGE_DIR=$(readlink -f "$RAW_STORAGE_DIR")
LAST_SESSION_FILE="$STORAGE_DIR/.last_session"

# --- LOGIKA AUTO START (Cek folder vms) ---
if [ -f "$LAST_SESSION_FILE" ]; then
  LAST_NAME=$(cat "$LAST_SESSION_FILE")
  # Cek apakah file startup ada di dalam folder vms
  if [ -f "$STORAGE_DIR/$LAST_NAME.sh" ]; then
    echo -e "${YELLOW}⚠️  Sesi terakhir: ${CYAN}$LAST_NAME${RESET}"
    echo -e "${GREEN}[Y]${RESET} = Masuk Lagi | ${RED}[N]${RESET} = Stop & Keluar"
    read -rp "Pilih (y/n): " AUTO_CHOICE
    if [[ "$AUTO_CHOICE" =~ ^[Yy]$ ]]; then
      docker stop "$LAST_NAME" 2>/dev/null || true
      bash "$STORAGE_DIR/$LAST_NAME.sh"
      exit 0
    else
      docker stop "$LAST_NAME" 2>/dev/null || true
      exit 0 
    fi
  fi
fi

# Banner
clear
echo -e "${BOLD}${CYAN}"
cat << "EOF"
██████╗   ██╗   ███████╗  ███╗   ███╗   █████╗   ███╗   ██╗
██╔══██╗  ██║   ██╔════╝  ████╗ ████║  ██╔══██╗  ████╗  ██║
██████╔╝  ██║   ███████╗  ██╔████╔██║  ███████║  ██╔██╗ ██║
██╔══██╗  ██║   ╚════██║  ██║╚██╔╝██║  ██╔══██║  ██║╚██╗██║
██║  ██║  ██║   ███████║  ██║ ╚═╝ ██║  ██║  ██║  ██║ ╚████║
╚═╝  ╚═╝  ╚═╝   ╚══════╝  ╚═╝     ╚═╝  ╚═╝  ╚═╝  ╚═╝  ╚═══╝
EOF
echo -e "${RESET}"
echo -e "\033[1;32m✨ Make By Manz & Ndaa (Folder ../vms)\033[0m"
echo -e "Lokasi Data: ${YELLOW}$STORAGE_DIR${RESET}"
sleep 0.5
echo ""

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} 🔄 Reconnect ke Sesi Terakhir"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container & File"
  echo -e "${YELLOW}6)${RESET} ⚡ Pasang Auto-Start (FIX)"
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

      read -rp "Nama Sesi (cth: myvps): " SESSION_NAME
      FINAL_NAME="${NAME}_${SESSION_NAME}"

      read -rp "RAM (cth: 5G): " RAM
      read -rp "CPU (cth: 2): " CPU
      read -rp "Disk (cth: 20G): " DISK

      # Simpan file .sh di folder ../vms/
      FILE="$STORAGE_DIR/$FINAL_NAME.sh"
      
      # Simpan history sesi
      echo "$FINAL_NAME" > "$LAST_SESSION_FILE"

      # Buat script startup
      cat > "$FILE" <<EOF
#!/bin/bash
docker stop "$FINAL_NAME" 2>/dev/null || true
docker rm -f "$FINAL_NAME" 2>/dev/null || true
docker run -it --rm \\
  --name "$FINAL_NAME" \\
  --device /dev/kvm \\
  -v "$STORAGE_DIR/vmdata":/vmdata \\
  -e RAM="$RAM" \\
  -e CPU="$CPU" \\
  -e DISK_SIZE="$DISK" \\
  "$IMAGE"
EOF
      chmod +x "$FILE"
      echo -e "${GREEN}Script disimpan di: $FILE${RESET}"
      sleep 1
      bash "$FILE"
      ;;

    2)
      clear
      docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}"
      read -rp "Enter..." ;;

    3)
      clear
      if [ -f "$LAST_SESSION_FILE" ]; then
         LAST_NAME=$(cat "$LAST_SESSION_FILE")
         echo -e "Sesi terakhir: ${GREEN}$LAST_NAME${RESET}"
         docker stop "$LAST_NAME" 2>/dev/null
         
         # Cek file di folder vms
         TARGET_FILE="$STORAGE_DIR/$LAST_NAME.sh"
         if [ -f "$TARGET_FILE" ]; then
            bash "$TARGET_FILE"
         else
            echo "Script hilang dari folder vms."
            read -rp "Enter..."
         fi
      else
         echo "Belum ada history."
         read -rp "Enter..."
      fi
      ;;

    4)
      clear
      docker ps --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      docker stop "$C"
      ;;

    5)
      clear
      echo -e "${RED}${BOLD}🗑️  HAPUS VPS (Dari folder vms)${RESET}"
      
      i=1
      declare -a VPS_FILES
      FOUND=0
      
      if [ -d "$STORAGE_DIR" ]; then
          # Scan file .sh di folder vms
          for f in "$STORAGE_DIR"/*.sh; do
              [ -e "$f" ] || continue
              FILENAME_ONLY=$(basename "$f")
              echo -e "${YELLOW}$i)${RESET} $FILENAME_ONLY"
              VPS_FILES[$i]="$f"
              ((i++))
              FOUND=1
          done
      fi

      if [ "$FOUND" -eq 0 ]; then
          echo -e "${RED}Tidak ada file VPS di folder $STORAGE_DIR.${RESET}"
          read -rp "Enter..."
          continue
      fi

      echo -e "${YELLOW}0)${RESET} Batal"
      echo ""
      read -rp "Pilih Nomor: " CHOICE

      if [ "$CHOICE" -eq 0 ]; then continue; fi

      SELECTED_FILE_PATH="${VPS_FILES[$CHOICE]}"
      if [ -z "$SELECTED_FILE_PATH" ]; then
          echo "Pilihan salah."
          continue
      fi

      NAME_NO_EXT=$(basename "$SELECTED_FILE_PATH" .sh)
      echo -e "${CYAN}Menghapus: $NAME_NO_EXT...${RESET}"
      
      # 1. Hapus Container
      docker stop "$NAME_NO_EXT" 2>/dev/null || true
      docker rm -f "$NAME_NO_EXT" 2>/dev/null || true
      
      # 2. Hapus File Script
      rm -f "$SELECTED_FILE_PATH"
      
      # 3. Hapus History
      rm -f "$LAST_SESSION_FILE"
      
      echo -e "${GREEN}Selesai.${RESET}"
      
      # Reset folder vmdata jika semua script sudah habis (Opsional, biar bersih)
      if ! ls "$STORAGE_DIR"/*.sh 1> /dev/null 2>&1; then
          echo -e "${YELLOW}Semua VPS habis, mereset folder vmdata...${RESET}"
          rm -rf "$STORAGE_DIR/vmdata"
          mkdir -p "$STORAGE_DIR/vmdata"
      fi
      read -rp "Enter..." 
      ;;

    6)
      clear
      BASHRC_FILE="$HOME/.bashrc"
      CMD="bash $SCRIPT_PATH"

      echo -e "Script Panel ada di: ${CYAN}$SCRIPT_PATH${RESET}"
      
      # Bersihkan dulu yang lama/error
      sed -i '/\/proc\//d' "$BASHRC_FILE" 2>/dev/null
      sed -i '/Auto Start Panel VPS/d' "$BASHRC_FILE" 2>/dev/null
      
      # Langsung pasang
      if grep -q "$SCRIPT_PATH" "$BASHRC_FILE"; then
          echo -e "${YELLOW}Auto-start sudah ada.${RESET}"
          read -rp "Hapus? (y/n): " DEL
          if [[ "$DEL" == "y" ]]; then
             sed -i "\|$SCRIPT_PATH|d" "$BASHRC_FILE"
             echo "Dihapus."
          fi
      else
          echo "" >> "$BASHRC_FILE"
          echo "# Auto Start Panel VPS" >> "$BASHRC_FILE"
          echo "$CMD" >> "$BASHRC_FILE"
          echo -e "${GREEN}Sukses! Perintah sudah dimasukkan ke .bashrc${RESET}"
      fi
      read -rp "Enter..."
      ;;

    0)
      clear
      exit 0
      ;;
  esac
  clear
done
