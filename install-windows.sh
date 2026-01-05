#!/bin/bash
shopt -s nullglob

# Fungsi untuk install Firefox di dalam container
install_firefox_in_container() {
    local container_name="$1"
    echo "========================================="
    echo "🚀 Memulai Auto Install Firefox Terbaru..."
    echo "========================================="
    
    # Menjalankan perintah instalasi di dalam container
    docker exec -t "$container_name" /bin/bash -c '
    echo "Update system..."
    apt-get update >/dev/null 2>&1
    apt-get install -y wget gnupg >/dev/null 2>&1
    
    echo "Menghapus Firefox lama..."
    apt-get remove firefox firefox-esr -y >/dev/null 2>&1
    
    echo "Menambahkan Keyring Mozilla..."
    install -d -m 0755 /etc/apt/keyrings
    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | \
    tee /etc/apt/keyrings/mozilla.gpg > /dev/null
    
    echo "Menambahkan Repository Mozilla..."
    echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main" | \
    tee /etc/apt/sources.list.d/mozilla.list
    
    echo "Install Firefox Stable..."
    apt-get update >/dev/null 2>&1
    apt-get install firefox -y
    '
    
    echo "========================================="
    echo "✅ Firefox terbaru berhasil diinstal!"
    echo "========================================="
}

while true; do
clear
echo "========================================="
echo "         PANEL VIRTUAL SYSTEM"
echo "========================================="
echo "1. Jalankan Windows baru"
echo "2. Ubuntu Desktop (VNC) [Auto-Start]"
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
        
        # Start service jika perlu (untuk memastikan jalan)
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
    # Cek apakah container sudah ada  
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
                echo "Akses di: http://localhost:6080"
                ;;
            3)  
                echo "Menghentikan container..."  
                docker stop $CONTAINER_NAME >/dev/null 2>&1  
                echo "✅ Berhenti. (Tidak akan auto-start sampai dinyalakan lagi)"  
                ;;  
            4)  
                echo "Menampilkan log (Ctrl + P lalu Ctrl + Q untuk keluar)"  
                docker attach $CONTAINER_NAME  
                ;;  
            5)  
                echo "Menghapus container lama dan membuat baru..."  
                docker rm -f $CONTAINER_NAME >/dev/null 2>&1  
                
                # Start Baru dengan Auto-Start Policy
                docker run -d --name $CONTAINER_NAME \
                    --restart unless-stopped \
                    -p 6080:80 \
                    -e RESOLUTION=$FIXED_RESOLUTION \
                    -v /dev/shm:/dev/shm \
                    -v "$DATA_DIR":/root \
                    dorowu/ubuntu-desktop-lxde-vnc >/dev/null
                
                echo "Container baru berjalan dengan resolusi $FIXED_RESOLUTION"
                
                # Panggil fungsi install firefox
                install_firefox_in_container $CONTAINER_NAME
                
                echo "Akses di: http://localhost:6080"
                ;;  
            0) continue ;;  
            *) echo "Pilihan tidak valid."; sleep 1 ;;  
        esac  

        read -p "Tekan Enter untuk kembali ke menu..."  
        continue  
    fi  

    # Jika container belum ada, buat baru langsung
    echo  
    echo "Menjalankan Ubuntu Desktop baru..."
    echo "Menggunakan Resolusi Tetap: $FIXED_RESOLUTION"
    echo "Set Auto-Start: ON (Akan nyala otomatis jika VPS reboot)"
    mkdir -p "$DATA_DIR"  

    # DITAMBAHKAN: --restart unless-stopped
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

    # Proses Install Firefox Otomatis
    install_firefox_in_container $CONTAINER_NAME

    echo "========================================="  
    echo "✅ Ubuntu Desktop VNC berjalan di port 6080"  
    echo "🌐 Akses melalui browser di: http://localhost:6080"  
    echo "🖥️  Resolusi: $FIXED_RESOLUTION"
    echo "🦊 Firefox: Terinstall"
    echo "🔄 Auto-Start: AKTIF"
    echo "========================================="  
    echo  
    sleep 2  
    read -p "Tekan Enter untuk kembali ke menu..."

fi

# ===== 1. Jalankan Windows baru =====

if [ "$SISTEM" == "1" ]; then
    echo
    echo "Pilih versi Windows:"
    echo " Value  | Version                   | Size"
    echo "--------------------------------------"
    echo " 11     | Windows 11 Pro             | 5.4 GB"
    echo " 11l    | Windows 11 LTSC            | 4.2 GB"
    echo " 11e    | Windows 11 Enterprise      | 5.8 GB"
    echo " 10     | Windows 10 Pro             | 5.7 GB"
    echo " 10l    | Windows 10 LTSC            | 4.6 GB"
    echo " 10e    | Windows 10 Enterprise      | 5.2 GB"
    echo " 8e     | Windows 8.1 Enterprise     | 3.7 GB"
    echo " 7e     | Windows 7 Enterprise       | 3.0 GB"
    echo " ve     | Windows Vista Enterprise   | 3.0 GB"
    echo " xp     | Windows XP Professional    | 0.6 GB"
    echo " 2025   | Windows Server 2025        | 5.0 GB"
    echo " 2022   | Windows Server 2022        | 4.7 GB"
    echo " 2019   | Windows Server 2019        | 5.3 GB"
    echo " 2016   | Windows Server 2016        | 6.5 GB"
    echo " 2012   | Windows Server 2012        | 4.3 GB"
    echo " 2008   | Windows Server 2008        | 3.0 GB"
    echo " 2003   | Windows Server 2003        | 0.6 GB"
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
    restart: unless-stopped
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
