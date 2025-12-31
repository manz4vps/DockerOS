#!/bin/bash
shopt -s nullglob

while true; do
clear
echo "========================================="
echo "         PANEL VIRTUAL SYSTEM"
echo "========================================="
echo "1. Jalankan Windows baru"
echo "2. Jalankan Ubuntu Desktop (VNC)"
echo "3. Lihat Windows aktif"
echo "4. Masuk ke Windows"
echo "5. Hapus Windows"
echo "6. Keluar"
echo "========================================="
read -p "Masukkan pilihan (1-6): " SISTEM

# ===== 2. Jalankan Ubuntu Desktop =====

if [ "$SISTEM" == "2" ]; then
CONTAINER_NAME="ubuntu_vnc"
DATA_DIR="$HOME/vnc_data"

echo  
# Cek apakah container sudah ada  
if [ "$(docker ps -a -q -f name=^${CONTAINER_NAME}$)" ]; then  
    if [ "$(docker ps -q -f name=^${CONTAINER_NAME}$)" ]; then  
        echo "Ubuntu Desktop VNC saat ini sudah berjalan!"  
    else  
        echo "Container ditemukan tapi sedang berhenti."  
    fi  
    echo "========================================="  
    echo "1. Jalankan / lanjutkan tanpa reset data"  
    echo "2. Ubah resolusi (data aman)"  
    echo "3. Lihat log"  
    echo "4. Hentikan container"  
    echo "5. Kembali ke menu utama"  
    echo "========================================="  
    read -p "Pilih opsi (1-5): " OPSI_VNC  

    case $OPSI_VNC in  
        1)  
            echo "Menjalankan kembali Ubuntu Desktop tanpa reset data..."  
            docker start $CONTAINER_NAME >/dev/null  
            echo "Container sudah dijalankan ulang!"  
            echo "Akses lagi di: http://localhost:6080"  
            ;;  
        2)  
            echo  
            # Default ke 1200x580 jika user langsung enter
            read -p "Masukkan resolusi baru (default: 1200x580): " RESOLUTION  
            RESOLUTION=${RESOLUTION:-1200x580}
            echo "Mengubah resolusi menjadi $RESOLUTION ..."  
            docker rm -f $CONTAINER_NAME >/dev/null 2>&1  
            docker run -d --name $CONTAINER_NAME \  
                -p 6080:80 \  
                -e RESOLUTION=$RESOLUTION \  
                -v /dev/shm:/dev/shm \  
                -v "$DATA_DIR":/root \  
                dorowu/ubuntu-desktop-lxde-vnc >/dev/null  
            
            # Re-install Firefox karena container di-recreate
            echo "Menginstall ulang Firefox..."
            docker exec -u 0 $CONTAINER_NAME bash -c 'apt-get update -qq && apt-get remove firefox firefox-esr -y && install -d -m 0755 /etc/apt/keyrings && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/mozilla.gpg > /dev/null && echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list && apt-get update -qq && apt-get install firefox -y' >/dev/null 2>&1
            
            echo "Container di-restart dengan resolusi baru & Firefox!"  
            echo "Akses lagi di: http://localhost:6080"  
            ;;  
        3)  
            echo  
            echo "Menampilkan log (Ctrl + P lalu Ctrl + Q untuk keluar tanpa stop)"  
            echo "========================================="  
            docker attach $CONTAINER_NAME  
            ;;  
        4)  
            echo "Menghentikan container..."  
            docker stop $CONTAINER_NAME >/dev/null 2>&1  
            echo "Container Ubuntu Desktop sudah dihentikan."  
            ;;  
        5) continue ;;  
        *) echo "Pilihan tidak valid."; sleep 1 ;;  
    esac  

    read -p "Tekan Enter untuk kembali ke menu..."  
    continue  
fi  

echo  
echo "=== Pengaturan Ubuntu Desktop (VNC) ==="  
echo "1. Gunakan resolusi 1200x580 (Default)"  
echo "2. Gunakan resolusi 1612x720"  
echo "3. Masukkan resolusi manual"  
echo "4. Kembali ke menu utama"  
echo  
read -p "Pilih opsi resolusi (1-4): " OPSI  

case $OPSI in  
    1) RESOLUTION="1200x580" ;;  
    2) RESOLUTION="1612x720" ;;  
    3) read -p "Masukkan resolusi (contoh: 1200x580): " RESOLUTION ;;  
    4) continue ;;  
    *) RESOLUTION="1200x580" ;;  
esac  

echo  
echo "Menjalankan Ubuntu Desktop dengan resolusi ${RESOLUTION}..."  
mkdir -p "$DATA_DIR"  

CONTAINER_ID=$(docker run -d --name $CONTAINER_NAME \  
    -p 6080:80 \  
    -e RESOLUTION=$RESOLUTION \  
    -v /dev/shm:/dev/shm \  
    -v "$DATA_DIR":/root \  
    dorowu/ubuntu-desktop-lxde-vnc)  

if [ $? -ne 0 ]; then  
    echo "Gagal menjalankan container VNC!"  
    read -p "Tekan Enter untuk kembali ke menu..."  
    continue  
fi  

# === AUTO INSTALL FIREFOX BLOCK ===
echo "========================================="
echo "⚙️  Sedang menginstall Firefox Terbaru..."
echo "⏳ Mohon tunggu sebentar (bisa memakan waktu 1-3 menit)..."

# Menjalankan perintah install di dalam container sebagai root
docker exec -u 0 $CONTAINER_NAME bash -c '
apt-get update -qq
apt-get remove firefox firefox-esr -y
install -d -m 0755 /etc/apt/keyrings
wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/mozilla.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mozilla.gpg] https://packages.mozilla.org/apt mozilla main" | tee /etc/apt/sources.list.d/mozilla.list
apt-get update -qq
apt-get install firefox -y
'
echo "✅ Firefox berhasil diinstall!"
# ==================================

echo "========================================="  
echo "Ubuntu Desktop VNC berjalan di port 6080"  
echo "Akses melalui browser di: http://localhost:6080"  
echo "Data tersimpan di: $DATA_DIR"  
echo "Container ID: $CONTAINER_ID"  
echo "========================================="  
echo  
echo "Menampilkan log secara real-time..."  
echo "(Tekan Ctrl + P lalu Ctrl + Q untuk keluar tanpa menghentikan VNC)"  
echo "========================================="  
sleep 2  
docker attach $CONTAINER_NAME  
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
