#!/bin/bash
shopt -s nullglob

# Fungsi untuk install Firefox + AUTOSTART
install_firefox_in_container() {
    local container_name="$1"
    echo "========================================="
    echo "🚀 Memulai Auto Install Firefox + Auto Start..."
    echo "========================================="
    
    # Menjalankan perintah instalasi & konfigurasi di dalam container
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

    # --- BAGIAN PENTING: SETTING AUTOSTART ---
    echo "Mengatur Firefox agar jalan otomatis saat VNC nyala..."
    mkdir -p /root/.config/autostart
    cat <<EOF > /root/.config/autostart/firefox.desktop
[Desktop Entry]
Type=Application
Exec=firefox
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name[en_US]=Firefox
Name=Firefox
Comment[en_US]=Start Firefox Automatically
Comment=Start Firefox Automatically
EOF
    chmod +x /root/.config/autostart/firefox.desktop
    # -----------------------------------------
    '
    
    echo "========================================="
    echo "✅ Firefox terinstall & Auto-Start aktif!"
    echo "========================================="
}

while true; do
clear
echo "========================================="
echo "         PANEL VIRTUAL SYSTEM"
echo "========================================="
echo "1. Jalankan Windows baru"
echo "2. Ubuntu Desktop (VNC) [Auto-Start & Firefox Auto-Open]"
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
                
                # Panggil fungsi install firefox + autostart
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
    echo "🦊 Auto-Open Firefox: AKTIF"
    echo "========================================="  
    echo  
    sleep 2  
    read -p "Tekan Enter untuk kembali ke menu..."

fi

# (Bagian Windows & Menu lain sama persis, tidak perlu diubah)
# ... COPY PASTE SISA SCRIPT SEBELUMNYA DI SINI ...
# Atau biarkan saja bagian bawahnya kalau kamu edit manual
