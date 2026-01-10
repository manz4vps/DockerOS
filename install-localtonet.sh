#!/bin/bash

# ==================================================
#  LocaltoNet Systemd Service Installer
#  Background Mode | Auto-Restart | Permanent IP
# ==================================================

# --- TOKEN KAMU (SUDAH TERTANAM) ---
MY_TOKEN="AFr0U2gjOyk4del8XSutYpC0Z6GEK9fDR"

# Pastikan script dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Harap jalankan script ini sebagai root (sudo)"
  exit 1
fi

clear
echo "--------------------------------------------------"
echo "⚙️  MEMULAI SETUP SYSTEMD SERVICE..."
echo "--------------------------------------------------"

# 1. Bersihkan instalasi lama & Matikan service jika ada
echo "🧹 Membersihkan sistem..."
systemctl stop localtonet 2>/dev/null
systemctl disable localtonet 2>/dev/null
rm -rf /usr/bin/localtonet
rm -rf localtonet
rm -f /etc/systemd/system/localtonet.service

# 2. Install Binary Terbaru
echo "⬇️  Download & Install LocaltoNet..."
curl -fsSL https://localtonet.com/install.sh | sh

# Pindahkan binary ke /usr/bin agar bisa dibaca systemd
if [ -f "localtonet" ]; then
    mv localtonet /usr/bin/localtonet
    chmod +x /usr/bin/localtonet
fi

# Cek apakah installasi sukses
if ! command -v localtonet &> /dev/null; then
    echo "❌ Gagal menginstall binary. Cek internet."
    exit 1
fi

# 3. Login Token
echo "🔐 Melakukan Login Token..."
localtonet authtoken "$MY_TOKEN"

if [ $? -ne 0 ]; then
    echo "❌ Login Gagal. Token salah atau koneksi error."
    exit 1
fi

# 4. Membuat File Service Systemd
echo "📝 Membuat file service (/etc/systemd/system/localtonet.service)..."

cat <<EOF > /etc/systemd/system/localtonet.service
[Unit]
Description=LocaltoNet Tunnel Service
After=network.target

[Service]
# Menjalankan localtonet tanpa argumen (Mode Dashboard)
ExecStart=/usr/bin/localtonet
Restart=always
RestartSec=3
User=root
WorkingDirectory=/root

[Install]
WantedBy=multi-user.target
EOF

# 5. Aktifkan Service
echo "🚀 Mengaktifkan Service..."
systemctl daemon-reload
systemctl enable localtonet
systemctl start localtonet

echo
echo "--------------------------------------------------"
echo "🎉 SUKSES! LocaltoNet sudah berjalan di Background."
echo "--------------------------------------------------"
echo "✅ Server akan otomatis nyala walaupun VPS direstart."
echo "✅ Tidak perlu buka terminal sshx lagi."
echo
echo "👉 Untuk melihat STATUS (IP & Koneksi):"
echo "   systemctl status localtonet"
echo
echo "👉 Untuk melihat LOG (Jika ada error):"
echo "   journalctl -u localtonet -f"
echo "--------------------------------------------------"
