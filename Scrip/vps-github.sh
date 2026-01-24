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

# --- KONFIGURASI PENYIMPANAN RAPI ---
# Folder tersembunyi untuk menyimpan semua sampah (script & data)
# Menggunakan titik (.) di depan agar tidak muncul di file explorer
STORAGE_DIR=".vms_storage"
LAST_SESSION_FILE="$STORAGE_DIR/.last_session"
SCRIPT_PATH=$(readlink -f "$0")
SCRIPT_NAME=$(basename "$0")

# Buat folder penyimpanan jika belum ada
mkdir -p "$STORAGE_DIR/vmdata"

# --- LOGIKA AUTO START (Safe Mode) ---
if [ -f "$LAST_SESSION_FILE" ]; then
  LAST_NAME=$(cat "$LAST_SESSION_FILE")
  # Cek file di dalam folder storage
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
echo -e "\033[1;32m✨ Make By Manz & Ndaa (Clean Workspace)\033[0m"
sleep 0.5
clear

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} 🔄 Reconnect ke Sesi Terakhir"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container"
  echo -e "${YELLOW}6)${RESET} ⚡ Pasang Auto-Start (.bashrc)"
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

      # Simpan file .sh di folder tersembunyi
      FILE="$STORAGE_DIR/$FINAL_NAME.sh"
      echo "$FINAL_NAME" > "$LAST_SESSION_FILE"

      # Perbaiki path volume docker agar mengarah ke folder storage
      cat > "$FILE" <<EOF
#!/bin/bash
docker stop "$FINAL_NAME" 2>/dev/null || true
docker rm -f "$FINAL_NAME" 2>/dev/null || true
docker run -it --rm \\
  --name "$FINAL_NAME" \\
  --device /dev/kvm \\
  -v "\$PWD/$STORAGE_DIR/vmdata":/vmdata \\
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
      if [ -f "$LAST_SESSION_FILE" ]; then
         LAST_NAME=$(cat "$LAST_SESSION_FILE")
         echo -e "Sesi terakhir: ${GREEN}$LAST_NAME${RESET}"
         docker stop "$LAST_NAME" 2>/dev/null
         # Cek path baru
         if [ -f "$STORAGE_DIR/$LAST_NAME.sh" ]; then
            bash "$STORAGE_DIR/$LAST_NAME.sh"
         else
            echo "Script hilang dari penyimpanan."
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
      echo -e "${RED}${BOLD}🗑️  PILIH VPS YANG MAU DIHAPUS TOTAL${RESET}"
      echo -e "(Container + File tersembunyi + Data akan hilang)"
      echo ""

      # --- LOGIKA LIST FILE NOMOR (SCAN FOLDER HIDDEN) ---
      i=1
      declare -a VPS_FILES
      FOUND=0
      
      # Cek folder storage
      if [ -d "$STORAGE_DIR" ]; then
          # Loop cari file .sh di dalam folder storage
          for f in "$STORAGE_DIR"/*.sh; do
              [ -e "$f" ] || continue
              
              # Tampilkan nama file saja tanpa path folder biar enak dibaca
              FILENAME_ONLY=$(basename "$f")
              
              echo -e "${YELLOW}$i)${RESET} $FILENAME_ONLY"
              VPS_FILES[$i]="$f" # Simpan path lengkapnya di array
              ((i++))
              FOUND=1
          done
      fi

      if [ "$FOUND" -eq 0 ]; then
          echo -e "${RED}Tidak ada file VPS tersimpan.${RESET}"
          read -rp "Enter..."
          continue
      fi

      echo -e "${YELLOW}0)${RESET} Batal"
      echo ""
      read -rp "Pilih Nomor: " CHOICE

      if [ "$CHOICE" -eq 0 ]; then
          continue
      fi

      # Ambil path file lengkap dari array
      SELECTED_FILE_PATH="${VPS_FILES[$CHOICE]}"

      if [ -z "$SELECTED_FILE_PATH" ]; then
          echo -e "${RED}Pilihan nomor tidak valid!${RESET}"
          read -rp "Enter..."
          continue
      fi

      # Ambil nama container dari nama file
      SELECTED_FILENAME=$(basename "$SELECTED_FILE_PATH")
      NAME_NO_EXT="${SELECTED_FILENAME%.sh}"
      
      echo -e "${CYAN}Memproses penghapusan: ${BOLD}$NAME_NO_EXT${RESET}..."
      
      # 1. Stop & Hapus Docker Container
      docker stop "$NAME_NO_EXT" 2>/dev/null || true
      docker rm -f "$NAME_NO_EXT" 2>/dev/null || true
      
      # 2. Hapus File Script di folder storage
      rm -f "$SELECTED_FILE_PATH"
      
      # 3. Hapus Data (Opsional: Bersihkan folder vmdata atau biarkan folder kosong)
      # Untuk keamanan, kita hapus isi vmdata tapi foldernya biarin aja buat sesi lain
      # Atau reset total folder storage kalau mau ekstrem
      
      # Hapus Session File
      rm -f "$LAST_SESSION_FILE"

      echo -e "${GREEN}✅ SUKSES! VPS $NAME_NO_EXT telah dihapus bersih.${RESET}"
      
      # Cek apakah folder storage kosong semua .sh nya
      if ! ls "$STORAGE_DIR"/*.sh 1> /dev/null 2>&1; then
          echo -e "${YELLOW}Info: Semua VPS habis. Mereset data disk...${RESET}"
          rm -rf "$STORAGE_DIR/vmdata"
          mkdir -p "$STORAGE_DIR/vmdata"
      fi

      read -rp "Enter..." 
      ;;

    6)
      clear
      BASHRC_FILE="$HOME/.bashrc"
      # Cek Error Path
      if [[ "$SCRIPT_PATH" == *"/proc/"* ]] || [[ ! -f "$SCRIPT_PATH" ]]; then
          echo -e "${RED}ERROR: Simpan script ini jadi file dulu!${RESET}"
          echo -e "Jangan di copas langsung ke terminal."
          read -rp "Enter..."
          continue
      fi
      
      CMD="bash $SCRIPT_PATH"
      
      # Auto Clean Error
      sed -i '/\/proc\//d' "$BASHRC_FILE" 2>/dev/null
      sed -i '/Auto Start Panel VPS/d' "$BASHRC_FILE" 2>/dev/null

      if grep -q "$SCRIPT_PATH" "$BASHRC_FILE"; then
          echo -e "${YELLOW}Auto-start sudah aktif.${RESET}"
          read -rp "Hapus? (y/n): " DEL
          if [[ "$DEL" == "y" ]]; then
             sed -i "\|$SCRIPT_PATH|d" "$BASHRC_FILE"
             echo "Dihapus."
          fi
      else
          echo "" >> "$BASHRC_FILE"
          echo "# Auto Start Panel VPS" >> "$BASHRC_FILE"
          echo "$CMD" >> "$BASHRC_FILE"
          echo -e "${GREEN}Sukses dipasang ke .bashrc${RESET}"
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
