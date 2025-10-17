#!/bin/bash

# ========== PILIH SISTEM ==========
clear
echo "========================================="
echo "   PILIH SISTEM YANG INGIN DIJALANKAN   "
echo "========================================="
echo "1. Windows (RDP)"
echo "2. Ubuntu Desktop (VNC)"
echo "========================================="
read -p "Masukkan pilihan (1/2): " SISTEM

if [ "$SISTEM" == "2" ]; then
    echo
    echo "=== Pengaturan Ubuntu Desktop (VNC) ==="
    echo "1. Gunakan preset resolusi 1612x720"
    echo "2. Gunakan preset resolusi 1090x512"
    echo "3. Masukkan resolusi manual"
    echo
    read -p "Pilih opsi resolusi (1-3): " OPSI

    case $OPSI in
        1)
            RESOLUTION="1612x720"
            ;;
        2)
            RESOLUTION="1090x512"
            ;;
        3)
            read -p "Masukkan resolusi (contoh: 1280x720): " RESOLUTION
            ;;
        *)
            echo "Pilihan tidak valid. Menggunakan resolusi default 1280x720."
            RESOLUTION="1280x720"
            ;;
    esac

    echo
    echo "Menjalankan Ubuntu Desktop dengan resolusi ${RESOLUTION}..."
    docker run -d -p 6080:80 -e RESOLUTION=$RESOLUTION -v /dev/shm:/dev/shm dorowu/ubuntu-desktop-lxde-vnc
    echo "========================================="
    echo "Ubuntu Desktop VNC berjalan di port 6080"
    echo "Akses melalui browser di: http://localhost:6080"
    echo "========================================="
    exit 0
fi

# ========== PILIHAN WINDOWS ==========
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

# Input dengan default value
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

# Nama file yaml berdasarkan versi
YAML_FILE="windows${VERSION}.yml"

# ========== Generate docker-compose.yml ==========
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

# ========== Jalankan Container ==========
echo "========================================="
echo "File $YAML_FILE berhasil dibuat."
echo "Sekarang menjalankan docker-compose..."
echo "========================================="
sudo docker-compose -f $YAML_FILE up
sudo docker attach windows
