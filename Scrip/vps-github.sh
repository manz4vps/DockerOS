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

# File history & Path Script
LAST_SESSION_FILE=".last_session"
# Menggunakan readlink untuk memastikan path absolut (bukan relative)
SCRIPT_PATH=$(readlink -f "$0")

# --- LOGIKA AUTO START DI AWAL (Saat Terminal Baru) ---
if [ -f "$LAST_SESSION_FILE" ]; then
  LAST_NAME=$(cat "$LAST_SESSION_FILE")
  
  # Cek jika container/file startup masih ada
  if [ -f "$LAST_NAME.sh" ]; then
    echo -e "${YELLOW}⚠️  Sesi terakhir terdeteksi: ${CYAN}$LAST_NAME${RESET}"
    echo -e "Github/Terminal mungkin baru restart."
    echo -e "${GREEN}Y${RESET} = Stop lama & Masuk lagi | ${RED}N${RESET} = Stop lama & Keluar"
    read -rp "Lanjut masuk container ini? (y/n): " AUTO_CHOICE
    
    if [[ "$AUTO_CHOICE" =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Memproses Auto Start...${RESET}"
      # Stop dulu biar gak conflict
      docker stop "$LAST_NAME" 2>/dev/null || true
      # Jalankan ulang
      bash "$LAST_NAME.sh"
      exit 0
    else
      echo -e "${RED}Oke, container dimatikan. Bye!${RESET}"
      docker stop "$LAST_NAME" 2>/dev/null || true
      exit 0 # Langsung keluar terminal sesuai request
    fi
  fi
fi
# -----------------------------------------------------

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

echo -e "\033[1;32m✨ Make By Manz & Ndaa (Fixed .bashrc Logic)\033[0m"
sleep 0.5
clear

# Menu utama
while true; do
  echo -e "${BOLD}${CYAN}🚀 === MENU OS VPS ===${RESET}"
  echo -e "${YELLOW}1)${RESET} 🧱 Buat OS VPS Baru"
  echo -e "${YELLOW}2)${RESET} 🔍 Lihat Container Aktif"
  echo -e "${YELLOW}3)${RESET} 🔄 Reconnect ke Sesi Terakhir"
  echo -e "${YELLOW}4)${RESET} ⏹️  Stop Container"
  echo -e "${YELLOW}5)${RESET} 🗑️  Hapus Container & Data (BERSIH)"
  echo -e "${YELLOW}6)${RESET} ⚡ Pasang Auto-Start"
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

      read -rp "Nama Sesi (bebas, cth: myvps): " SESSION_NAME
      FINAL_NAME="${NAME}_${SESSION_NAME}"

      read -rp "RAM (contoh 5G): " RAM
      read -rp "CPU (contoh 2): " CPU
      read -rp "Disk (contoh 20G): " DISK

      mkdir -p vmdata
      FILE="$FINAL_NAME.sh"

      # Simpan sesi
      echo "$FINAL_NAME" > "$LAST_SESSION_FILE"

      cat > "$FILE" <<EOF
#!/bin/bash
docker stop "$FINAL_NAME" 2>/dev/null || true
docker rm -f "$FINAL_NAME" 2>/dev/null || true
docker run -it --rm \\
  --name "$FINAL_NAME" \\
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
      # Reconnect Manual
      clear
      if [ -f "$LAST_SESSION_FILE" ]; then
         LAST_NAME=$(cat "$LAST_SESSION_FILE")
         echo -e "Sesi terakhir: ${GREEN}$LAST_NAME${RESET}"
         docker stop "$LAST_NAME" 2>/dev/null
         if [ -f "$LAST_NAME.sh" ]; then
            bash "$LAST_NAME.sh"
         else
            echo "Script hilang."
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
      echo -e "${RED}HAPUS TOTAL (Container + Data vmdata)${RESET}"
      docker ps -a --format "table {{.Names}}\t{{.Status}}"
      read -rp "Nama container: " C
      
      docker stop "$C" 2>/dev/null || true
      docker rm -f "$C" 2>/dev/null || true
      rm -f "$C.sh"
      rm -rf vmdata  # Hapus folder data
      rm -f "$LAST_SESSION_FILE"
      
      echo -e "${GREEN}Bersih total.${RESET}"
      read -rp "Enter..." 
      ;;

    6)
      # MENU BARU: Pasang ke .bashrc
      clear
      BASHRC_FILE="$HOME/.bashrc"
      
      # --- SAFETY CHECK (PENTING) ---
      # Mencegah path '/proc/' yang bikin error di screenshot kamu
      if [[ "$SCRIPT_PATH" == *"/proc/"* ]] || [[ ! -f "$SCRIPT_PATH" ]]; then
          echo -e "${RED}⛔ ERROR PATH TERDETEKSI!${RESET}"
          echo -e "Kamu menjalankan script ini langsung (copy-paste) atau via pipe."
          echo -e "Ini yang bikin error ${YELLOW}bash: /proc/...${RESET} di terminal kamu."
          echo
          echo -e "${GREEN}SOLUSI:${RESET}"
          echo -e "1. Simpan script ini jadi file, misal: ${BOLD}panel.sh${RESET}"
          echo -e "2. Jalankan file-nya: ${BOLD}./panel.sh${RESET}"
          echo -e "3. Baru pilih menu nomor 6 lagi."
          read -rp "Enter untuk kembali..."
          continue
      fi
      
      CMD="bash $SCRIPT_PATH"
      
      # Bersihkan error lama (yang /proc/ tadi) otomatis
      if grep -q "/proc/" "$BASHRC_FILE"; then
         echo -e "${YELLOW}Membersihkan baris error lama di .bashrc...${RESET}"
         sed -i '/\/proc\//d' "$BASHRC_FILE"
      fi

      # Cek apakah sudah ada di .bashrc
      if grep -q "$SCRIPT_PATH" "$BASHRC_FILE"; then
          echo -e "${YELLOW}Auto-start sudah terpasang sebelumnya!${RESET}"
          echo -e "Path: $SCRIPT_PATH"
          echo -e "Mau dihapus dari auto-start? (y/n)"
          read -rp "Pilih: " DEL_OPT
          if [[ "$DEL_OPT" == "y" ]]; then
              # Hapus baris yang mengandung path script ini
              sed -i "\|$SCRIPT_PATH|d" "$BASHRC_FILE"
              sed -i '/# Auto Start Panel VPS/d' "$BASHRC_FILE"
              echo -e "${GREEN}Auto-start dimatikan.${RESET}"
          fi
      else
          echo -e "${CYAN}Menambahkan script ke .bashrc...${RESET}"
          # Hapus entri lama biar gak double
          sed -i '/Auto Start Panel VPS/d' "$BASHRC_FILE"
          
          echo "" >> "$BASHRC_FILE"
          echo "# Auto Start Panel VPS" >> "$BASHRC_FILE"
          echo "$CMD" >> "$BASHRC_FILE"
          echo -e "${GREEN}Sukses! Script akan jalan otomatis saat buka terminal baru.${RESET}"
      fi
      read -rp "Enter..."
      ;;

    0)
      clear
      echo -e "${GREEN}Keluar...${RESET}"
      exit 0
      ;;
  esac
  clear
done
