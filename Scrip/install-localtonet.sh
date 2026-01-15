#!/bin/bash

# =======================================================
#  LocaltoNet Smart Installer (Systemd)
#  Fitur: Auto-Save Token & Background Service
# =======================================================

TOKEN_FILE="/etc/localtonet_token"

# Pastikan dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Jalankan script ini pakai sudo/root ya bro!"
  exit 1
fi

clear
echo "--------------------------------------------------"
echo "⚙️  MEMULAI SETUP LOCALTONET SMART..."
echo "--------------------------------------------------"

# 1. CEK & MINTA TOKEN (LOGIKA SAVE)
# Cek apakah file token ada dan ada isinya
if [[ -f "$TOKEN_FILE" && -s "$TOKEN_FILE" ]]; then
    MY_TOKEN=$(cat "$TOKEN_FILE")
    echo "✅ Token tersimpan ditemukan!"
    echo "🔑 Menggunakan Token: ${MY_TOKEN:0:10}......"
else
    echo "⚠️  Token belum tersimpan."
    echo "--------------------------------------------------"
    read -p "👉 Paste Auth Token LocaltoNet kamu disini: " USER_INPUT
    
    # Validasi biar gak kosong
    if [[ -z "$USER_INPUT" ]]; then
        echo "❌ Token tidak boleh kosong bro!"
        exit 1
    fi
    
    # Simpan token ke file
    echo "$USER_INPUT" > "$TOKEN_FILE"
    MY_TOKEN="$USER_INPUT"
    echo "💾 Token berhasil disimpan! Besok gak perlu isi lagi."
fi

# 2. BERSIH-BERSIH (Matikan yang lama)
echo
echo "🧹 Membersihkan service lama..."
systemctl stop localtonet 2>/dev/null
systemctl disable localtonet 2>/dev/null
pkill -f localtonet
rm -f /etc/systemd/system/localtonet.service

# 3. INSTALL APLIKASI
# Cek kalau belum ada, download dulu
if ! command -v localtonet &> /dev/null; then
    echo "⬇️  Mendownload LocaltoNet..."
    curl -fsSL https://localtonet.com/install.sh | sh
    
    # Pindahkan ke folder sistem biar rapi
    if [ -f "localtonet" ]; then
        mv localtonet /usr/bin/localtonet
        chmod +x /usr/bin/localtonet
    fi
else
    echo "✅ Aplikasi LocaltoNet sudah terinstall."
fi

# 4. LOGIN KE AKUN
echo "🔌 Menghubungkan Token..."
localtonet authtoken "$MY_TOKEN"

if [ $? -ne 0 ]; then
    echo "❌ Gagal Login! Token mungkin salah."
    echo "💡 Hapus file token lama dengan perintah: rm $TOKEN_FILE"
    echo "   Lalu jalankan script ini lagi."
    exit 1
fi

# 5. BUAT SERVICE BACKGROUND (Systemd)
echo "📝 Membuat Service Background..."

cat <<EOF > /etc/systemd/system/localtonet.service
[Unit]
Description=LocaltoNet Tunnel Service
After=network.target

[Service]
# Jalan tanpa argumen agar baca settingan Dashboard (IP Permanen)
ExecStart=/usr/bin/localtonet
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

# 6. JALANKAN SERVICE
echo "🚀 Mengaktifkan Server..."
systemctl daemon-reload
systemctl enable localtonet
systemctl start localtonet

echo
echo "=================================================="
echo "🎉 SUKSES! SERVER SUDAH JALAN DI BACKGROUND"
echo "=================================================="
echo "✅ Token sudah disimpan di: $TOKEN_FILE"
echo "✅ Server otomatis nyala kalau VPS restart"
echo
echo "👉 Cek Status & IP (Lihat Log):"
echo "   journalctl -u localtonet -n 20 --no-pager"
echo "=================================================="
