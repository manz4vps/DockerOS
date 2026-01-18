#!/bin/bash
shopt -s nullglob

# =========================================================
# PROGRAM UTAMA
# =========================================================

while true; do
clear
echo "========================================="
echo "          PANEL VIRTUAL SYSTEM (MANZ4VPS)"
echo "========================================="
echo "1. Jalankan Windows baru"
echo "2. Jalankan Ubuntu Desktop (VNC)"
echo "3. Lihat Windows aktif"
echo "4. Masuk ke Windows"
echo "5. Hapus Windows"
echo "6. Keluar"
echo "========================================="
read -p "Masukkan pilihan (1-6): " SISTEM

# =========================================================
# MENU 2: UBUNTU DESKTOP VNC (CURL ONE-LINER)
# =========================================================

if [ "$SISTEM" == "2" ]; then
    echo
    echo "========================================="
    echo "🚀 MENJALANKAN SCRIPT NO-VNC (MANZ4VPS)..."
    echo "========================================="
    
    # 1. Pastikan Curl ada
    if ! command -v curl &> /dev/null; then
        echo "⚠️  Curl tidak ditemukan. Menginstall..."
        sudo apt-get update >/dev/null
        sudo apt-get install -y curl >/dev/null
    fi

    # 2. Eksekusi Langsung (One-Liner)
    clear
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-noVNC.sh)

    # 3. Selesai
    echo
    read -p "Tekan Enter untuk kembali ke menu utama..."
    continue
fi

# =========================================================
# MENU 1: WINDOWS (DOCKER OS) - TETAP SAMA
# =========================================================

if [ "$SISTEM" == "1" ]; then
    echo
    echo "Pilih versi Windows:"
    echo " Value  | Version                       | Size"
    echo "--------------------------------------"
    echo " 11     | Windows 11 Pro               | 5.4 GB"
    echo " 11l    | Windows 11 LTSC              | 4.2 GB"
    echo " 11e    | Windows 11 Enterprise        | 5.8 GB"
    echo " 10     | Windows 10 Pro               | 5.7 GB"
    echo " 10l    | Windows 10 LTSC              | 4.6 GB"
    echo " 10e    | Windows 10 Enterprise        | 5.2 GB"
    echo " 8e     | Windows 8.1 Enterprise       | 3.7 GB"
    echo " 7e     | Windows 7 Enterprise         | 3.0 GB"
    echo " ve     | Windows Vista Enterprise     | 3.0 GB"
    echo " xp     | Windows XP Professional      | 0.6 GB"
    echo " 2025   | Windows Server 2025          | 5.0 GB"
    echo " 2022   | Windows Server 2022          | 4.7 GB"
    echo " 2019   | Windows Server 2019          | 5.3 GB"
    echo " 2016   | Windows Server 2016          | 6.5 GB"
    echo " 2012   | Windows Server 2012          | 4.3 GB"
    echo " 2008   | Windows Server 2008          | 3.0 GB"
    echo " 2003   | Windows Server 2003          | 0.6 GB"
    echo

    read -p "Masukkan value versi (default: 10l): " VERSION  
    VERSION=${VERSION:-10l}  

    read -p "Masukkan Username RDP (default: ManzXD): " USERNAME  
    USERNAME=${USERNAME:-ManzXD}  

    read -p "Masukkan Password RDP (default: ManzXD): " PASSWORD  
    PASSWORD=${PASSWORD:-ManzXD}  

    read -p "Masukkan RAM (default: 4G): " RAM  
    RAM=${RAM:-4G}  

    read -p "Masukkan jumlah CPU (default: 2): " CPU  
    CPU=${CPU:-2}  

    read -p "Masukkan Disk utama (default: 20G): " DISK1  
    DISK1=${DISK1:-20G}  

    read -p "Masukkan Disk kedua (default: 20G): " DISK2  
    DISK2=${DISK2:-20G}  

    YAML_FILE="windows${VERSION}.yml"  

cat > $YAML_FILE <<EOL
version: "3.8"
services:
  windows:
    image: manz4vps/windows
    container_name: windows
    environment:
      VERSION: "$VERSION"
      USERNAME: "$USERNAME"
      PASSWORD: "$PASSWORD"
      RAM_SIZE: "$RAM"
      CPU_CORES: "$CPU"
      DISK_SIZE: "$DISK1"
      DISK2_SIZE: "$DISK2"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - 8006:8006
      - 3389:3389/tcp
      - 3389:3389/udp
    stop_grace_period: 2m
EOL

    echo "========================================="  
    echo "File $YAML_FILE berhasil dibuat."  
    echo "Menjalankan docker-compose..."  
    echo "========================================="  
    sudo docker-compose -f $YAML_FILE up -d  
    echo "Windows berjalan. Gunakan menu '4' untuk masuk ke windows."  
    read -p "Tekan Enter untuk kembali ke menu..."
fi

# =========================================================
# MENU 3: LIHAT WINDOWS AKTIF
# =========================================================

if [ "$SISTEM" == "3" ]; then
    echo
    echo "=== DAFTAR WINDOWS AKTIF ==="
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo "============================="
    read -p "Tekan Enter untuk kembali ke menu..."
fi

# =========================================================
# MENU 4: MASUK KE WINDOWS
# =========================================================

if [ "$SISTEM" == "4" ]; then
    echo
    FILES=(windows*.yml)
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "Tidak ada file Windows ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        continue
    fi

    echo "=== PILIH FILE WINDOWS UNTUK MASUK ==="  
    i=1  
    for f in "${FILES[@]}"; do  
        echo "$i) $f"  
        ((i++))  
    done  
    echo "0) Kembali ke menu utama"  
    echo "==============================="  
    read -p "Pilih nomor file: " pilih  

    if [ "$pilih" == "0" ]; then  
        continue  
    fi  

    FILE=${FILES[$((pilih-1))]}  
    if [ -z "$FILE" ]; then  
        echo "Pilihan tidak valid."  
        read -p "Tekan Enter untuk kembali..."  
        continue  
    fi  

    echo "Menjalankan $FILE..."  
    sudo docker-compose -f "$FILE" up -d  
    sudo docker attach windows  
    read -p "Tekan Enter untuk kembali ke menu..."
fi

# =========================================================
# MENU 5: HAPUS WINDOWS
# =========================================================

if [ "$SISTEM" == "5" ]; then
    echo
    FILES=(windows*.yml)
    if [ ${#FILES[@]} -eq 0 ]; then
        echo "Tidak ada file Windows ditemukan!"
        read -p "Tekan Enter untuk kembali..."
        continue
    fi

    echo "=== PILIH FILE WINDOWS UNTUK DIHAPUS ==="  
    i=1  
    for f in "${FILES[@]}"; do  
        echo "$i) $f"  
        ((i++))  
    done  
    echo "0) Kembali ke menu utama"  
    echo "==============================="  
    read -p "Pilih nomor file: " pilih  

    if [ "$pilih" == "0" ]; then  
        continue  
    fi  

    FILE=${FILES[$((pilih-1))]}  
    if [ -z "$FILE" ]; then  
        echo "Pilihan tidak valid."  
        read -p "Tekan Enter untuk kembali..."  
        continue  
    fi  

    echo "Menghapus container & file $FILE..."  
    sudo docker-compose -f "$FILE" down  
    rm -f "$FILE"  
    echo "Selesai dihapus."  
    read -p "Tekan Enter untuk kembali ke menu..."
fi

# =========================================================
# MENU 6: KELUAR
# =========================================================

if [ "$SISTEM" == "6" ]; then
    clear
    echo "Terima kasih telah menggunakan panel ini!"
    exit 0
fi

done
