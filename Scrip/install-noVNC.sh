#!/bin/bash
# =========================================================
# CONFIG
# =========================================================
CONTAINER_NAME="ubuntu_vnc"
DATA_DIR="$HOME/vnc_data"
SERVICE_NAME="vnc-auto"

# Cek Docker
if ! command -v docker &> /dev/null; then
    sudo apt-get update && sudo apt-get install -y docker.io
fi

while true; do
    clear
    echo "========================================="
    echo "   PANEL VNC (FIREFOX + FILEZILLA)       "
    echo "========================================="
    echo "1. INSTALL / PERBAIKI"
    echo "2. RESTART SERVICE"
    echo "3. CEK STATUS"
    echo "4. HAPUS SEMUA"
    echo "0. KELUAR"
    echo "-----------------------------------------"
    read -p "Pilih: " OPSI

    case $OPSI in
        1)
            echo "🔥 Stop service lama..."
            sudo systemctl stop $SERVICE_NAME >/dev/null 2>&1
            sudo systemctl disable $SERVICE_NAME >/dev/null 2>&1
            rm -f /usr/local/bin/start-vnc-custom.sh

            # Cek apakah container perlu dibuat ulang? 
            if [ ! "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then
                echo "📦 Membuat Container Baru..."
                
                # --- LOGIKA BARU: DETEKSI KVM OTOMATIS ---
                KVM_ARGS=""
                if [ -e /dev/kvm ]; then
                    echo "🚀 KVM Ditemukan! Mengaktifkan Hardware Acceleration..."
                    KVM_ARGS="--device /dev/kvm --cap-add NET_ADMIN"
                else
                    echo "⚠️  /dev/kvm tidak ditemukan. Berjalan mode normal..."
                fi
                # -----------------------------------------

                docker run -d --name $CONTAINER_NAME \
                    --restart always \
                    $KVM_ARGS \
                    -p 6080:80 \
                    -e RESOLUTION=1200x580 \
                    -v /dev/shm:/dev/shm \
                    -v "$DATA_DIR":/root \
                    dorowu/ubuntu-desktop-lxde-vnc >/dev/null
                
                echo "⏳ Sedang menginstall Aplikasi (FileZilla & Firefox)..."
                echo "⏳ Proses ini mungkin memakan waktu 2-3 menit..."

                # Script Install: Hapus Chrome -> Install FileZilla -> Install Firefox
                docker exec -t $CONTAINER_NAME /bin/bash -c '
                    # 1. BERSIH-BERSIH CHROME
                    echo "🧹 Menghapus Google Chrome..."
                    rm -f /etc/apt/sources.list.d/google-chrome.list
                    apt-get update --allow-insecure-repositories || true
                    apt-get purge -y google-chrome-stable google-chrome-stable-sound || true
                    apt-get autoremove -y

                    # 2. PERSIAPAN TOOLS
                    apt-get install -y wget gnupg nano procps ca-certificates apt-transport-https software-properties-common

                    # 3. INSTALL FILEZILLA
                    echo "📂 Menginstall FileZilla..."
                    add-apt-repository universe -y
                    apt-get update
                    apt-get install -y filezilla

                    # 4. INSTALL FIREFOX (Fix GPG)
                    echo "🦊 Menginstall Firefox..."
                    apt-get remove firefox firefox-esr -y >/dev/null 2>&1
                    install -d -m 0755 /etc/apt/keyrings
                    wget --no-check-certificate -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/mozilla.gpg > /dev/null
                    echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list > /dev/null
                    echo -e "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000" > /etc/apt/preferences.d/mozilla
                    apt-get update
                    apt-get install -y firefox
                    mkdir -p /root/.mozilla/firefox
                    
                    # Pre-load firefox agar folder config terbentuk
                    timeout 5s firefox --headless >/dev/null 2>&1
                '
            else
                echo "✅ Container sudah ada. Melanjutkan setup Autostart..."
            fi

            echo "⚙️  Membuat Script Auto-Start (Mode Detached)..."
            cat <<EOF > /usr/local/bin/start-vnc-custom.sh
#!/bin/bash
docker start $CONTAINER_NAME
sleep 15
# Menjalankan Firefox di background saat VNC nyala
docker exec -d $CONTAINER_NAME /bin/bash -c "export DISPLAY=:1 && firefox --no-sandbox"
EOF
            chmod +x /usr/local/bin/start-vnc-custom.sh

            echo "⚙️  Memasang Systemd Service..."
            cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=Auto Start VNC Firefox + FileZilla Installed
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
ExecStart=/bin/bash /usr/local/bin/start-vnc-custom.sh
RemainAfterExit=yes
User=root

[Install]
WantedBy=multi-user.target
EOF

            echo "🔄 Mengaktifkan Service..."
            sudo systemctl daemon-reload
            sudo systemctl enable $SERVICE_NAME
            sudo systemctl start $SERVICE_NAME
            
            echo "✅ SELESAI! Chrome dihapus, FileZilla terinstall."
            echo "👉 Firefox akan terbuka otomatis."
            read -p "Tekan Enter..."
            ;;

        2)
            echo "🔄 Restarting Service..."
            sudo systemctl restart $SERVICE_NAME
            echo "✅ Service Restarted."
            read -p "Tekan Enter..."
            ;;
        3)
            sudo systemctl status $SERVICE_NAME
            read -p "Tekan Enter..."
            ;;
        4)
            echo "🗑️ Hapus Semua..."
            sudo systemctl stop $SERVICE_NAME
            sudo systemctl disable $SERVICE_NAME
            rm -f /etc/systemd/system/$SERVICE_NAME.service
            rm -f /usr/local/bin/start-vnc-custom.sh
            docker rm -f $CONTAINER_NAME
         
            echo "✅ Bersih."
            read -p "Tekan Enter..."
            ;;
        0)
            exit 0
            ;;
    esac
done
