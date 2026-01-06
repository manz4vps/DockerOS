#!/bin/bash
shopt -s nullglob

# =========================================================
# FUNGSI BARU: FIXED FIREFOX INSTALLER (ANTI CRASH)
# =========================================================
install_firefox_in_container() {
    local container_name="$1"
    echo "========================================="
    echo "🚀 Menginstall Firefox ESR (Versi Ringan & Stabil)..."
    echo "========================================="
    
    # Kita buka log-nya biar kelihatan kalau ada error saat install
    docker exec -t "$container_name" /bin/bash -c '
    
    # 1. Pastikan repository Universe aktif (Penting buat Ubuntu)
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository universe -y
    apt-get update

    # 2. Hapus Firefox versi Snap yang bikin error
    apt-get remove --purge -y firefox
    rm -rf /snap/firefox
    
    # 3. Install Firefox ESR (Versi .deb asli, bukan Snap)
    # Plus install library tambahan biar ga crash
    apt-get install -y firefox-esr libulockmgr1 libcanberra-gtk3-module dbus-x11

    # 4. BUAT SHORTCUT DI DESKTOP (Biar bisa di-klik manual)
    mkdir -p /root/Desktop
    cat <<EOF > /root/Desktop/Firefox.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Firefox Web Browser
Comment=Browse the World Wide Web
Exec=firefox-esr --no-sandbox --display=:1
Icon=firefox-esr
Path=
Terminal=false
StartupNotify=false
EOF
    chmod +x /root/Desktop/Firefox.desktop

    # 5. BUAT AUTOSTART (Lewat folder .config user)
    # Ini cara paling resmi di LXDE
    mkdir -p /root/.config/autostart
    cat <<EOF > /root/.config/autostart/firefox-autostart.desktop
[Desktop Entry]
Type=Application
Name=Firefox Autostart
Exec=sh -c "sleep 10; firefox-esr --no-sandbox --display=:1"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF
    
    chmod +x /root/.config/autostart/firefox-autostart.desktop
    
    # Fix permission folder vnc
    chown -R root:root /root/.config
    chown -R root:root /root/Desktop
    '
    
    echo "========================================="
    echo "✅ Firefox ESR Terinstall."
    echo "👉 Pilih menu '5. Reset Container' untuk menerapkan ulang."
    echo "👉 Nanti di Desktop akan ada icon 'Firefox Web Browser'."
    echo "👉 Kalau tidak muncul otomatis, coba klik dua kali icon di Desktop itu."
    echo "========================================="
}

# =========================================================
# PROGRAM UTAMA
# =========================================================

while true; do
clear
echo "========================================="
echo "          PANEL VIRTUAL SYSTEM (FIXED)"
echo "========================================="
echo "1. Jalankan Windows baru"
echo "2. Jalankan Ubuntu Desktop (VNC) [FIX Firefox]"
echo "3. Lihat Windows aktif"
echo "4. Masuk ke Windows"
echo "5. Hapus Windows"
echo "6. Keluar"
echo "========================================="
read -p "Masukkan pilihan (1-6): " SISTEM

# ===== 2. Jalankan Ubuntu Desktop =====

if [ "$SISTEM" == "2" ]; then
    
    # --- CEK OTOMATIS DOCKER.IO ---
    echo
    echo "========================================="
    echo "⚙️  MEMERIKSA KELENGKAPAN PAKET..."
    
    if ! command -v docker &> /dev/null; then
        echo "⚠️  Docker belum ditemukan."
        echo "📦  Sedang mendownload & menginstall docker.io..."
        
        # Update & Install Docker
        sudo apt-get update >/dev/null 2>&1
        sudo apt-get install -y docker.io
        
        # Start service jika perlu
        sudo service docker start >/dev/null 2>&1
        
        echo "✅  Docker berhasil diinstall!"
    else
        echo "✅  Docker sudah terinstall. Skip download."
    fi
    echo "========================================="
    sleep 1
    # ----------------------------------

    CONTAINER_NAME="ubuntu_vnc"
    DATA_DIR="$HOME/vnc_data"
    FIXED_RESOLUTION="1200x580"

    echo  
    if [ "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then  
        STATUS=$(docker inspect -f '{{.State.Status}}' $CONTAINER_NAME)
        
        if [ "$STATUS" == "running" ]; then  
            echo "✅ Ubuntu Desktop VNC sedang BERJALAN!"  
        else  
            echo "⏸️  Container ditemukan tapi sedang BERHENTI (STOPPED)."  
        fi  
        
        echo "========================================="  
        echo "1. Jalankan / Lanjutkan (Start)"  
        echo "2. Restart Service (Mulai Ulang)" 
        echo "3. Hentikan (Stop)"  
        echo "4. Lihat Log"  
        echo "5. Reset Container (Hapus & Buat Baru)"  
        echo "0. Kembali ke menu utama"  
        echo "========================================="  
        read -p "Pilih opsi (0-5): " OPSI_VNC  

        case $OPSI_VNC in  
            1)  
                echo "Menjalankan kembali Ubuntu Desktop..."  
                docker start $CONTAINER_NAME >/dev/null  
                echo "✅ Container berjalan!"  
                echo "Akses di: http://localhost:6080"  
                ;;  
            2)
                echo "Merestart service VNC..."
                docker restart $CONTAINER_NAME >/dev/null
                echo "✅ Berhasil direstart."
                echo "Firefox akan otomatis terbuka sebentar lagi..."
                ;;
            3)  
                echo "Menghentikan container..."  
                docker stop $CONTAINER_NAME >/dev/null 2>&1  
                echo "✅ Berhenti."  
                ;;  
            4)  
                docker attach $CONTAINER_NAME  
                ;;  
            5)  
                echo "Menghapus container lama dan membuat baru..."  
                docker rm -f $CONTAINER_NAME >/dev/null 2>&1  
                
                # Start Baru
                docker run -d --name $CONTAINER_NAME \
                    --restart unless-stopped \
                    -p 6080:80 \
                    -e RESOLUTION=$FIXED_RESOLUTION \
                    -v /dev/shm:/dev/shm \
                    -v "$DATA_DIR":/root \
                    dorowu/ubuntu-desktop-lxde-vnc >/dev/null
                
                echo "Container baru berjalan dengan resolusi $FIXED_RESOLUTION"
                
                # Panggil fungsi install firefox safe mode
                install_firefox_in_container $CONTAINER_NAME
                
                echo "Akses di: http://localhost:6080"
                ;;  
            0) continue ;;  
            *) echo "Pilihan tidak valid."; sleep 1 ;;  
        esac  

        read -p "Tekan Enter untuk kembali ke menu..."  
        continue  
    fi  

    # Jika container belum ada
    echo  
    echo "Menjalankan Ubuntu Desktop baru..."
    mkdir -p "$DATA_DIR"  

    CONTAINER_ID=$(docker run -d --name $CONTAINER_NAME \
        --restart unless-stopped \
        -p 6080:80 \
        -e RESOLUTION=$FIXED_RESOLUTION \
        -v /dev/shm:/dev/shm \
        -v "$DATA_DIR":/root \
        dorowu/ubuntu-desktop-lxde-vnc)  

    if [ $? -ne 0 ]; then  
        echo "❌ Gagal menjalankan container VNC!"  
        read -p "Tekan Enter untuk kembali ke menu..."  
        continue  
    fi  

    install_firefox_in_container $CONTAINER_NAME

    echo "========================================="  
    echo "✅ Ubuntu Desktop VNC berjalan"  
    echo "🌐 Akses: http://localhost:6080"  
    echo "🔄 Auto-Start VNC: AKTIF"
    echo "🦊 Auto-Open Firefox: AKTIF (Patched --no-sandbox)"
    echo "========================================="  
    echo  
    sleep 2  
    read -p "Tekan Enter untuk kembali ke menu..."

fi

# ===== 1. Jalankan Windows baru =====

if [ "$SISTEM" == "1" ]; then
    echo
    echo "Pilih versi Windows:"
    echo " Value  | Version                     | Size"
    echo "--------------------------------------"
    echo " 11     | Windows 11 Pro              | 5.4 GB"
    echo " 11l    | Windows 11 LTSC             | 4.2 GB"
    echo " 10     | Windows 10 Pro              | 5.7 GB"
    echo " 10l    | Windows 10 LTSC             | 4.6 GB"
    echo " 2022   | Windows Server 2022         | 4.7 GB"
    echo " 2019   | Windows Server 2019         | 5.3 GB"
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

# ===== 3. Lihat Windows aktif =====

if [ "$SISTEM" == "3" ]; then
    echo
    echo "=== DAFTAR WINDOWS AKTIF ==="
    sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo "============================="
    read -p "Tekan Enter untuk kembali ke menu..."
fi

# ===== 4. Masuk ke Windows =====

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

# ===== 5. Hapus Windows =====

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

# ===== 6. Keluar =====

if [ "$SISTEM" == "6" ]; then
    clear
    echo "Terima kasih telah menggunakan panel ini!"
    exit 0
fi

done
