#!/bin/bash

echo "========================================="
echo "  Mulai Setup Code Server Auto-Restart"
echo "========================================="

# Pindah ke home direktori
cd ~

# Hapus sisa file lama biar nggak error/bentrok kalau pernah install sebelumnya
echo "[1/6] Membersihkan file lama (jika ada)..."
sudo rm -rf code-server-4.115.0-linux-amd64
sudo rm -f code-server.tar.gz
sudo rm -rf /opt/code-server

# Download file
echo "[2/6] Mendownload Code Server v4.115.0..."
curl -L -o code-server.tar.gz https://github.com/coder/code-server/releases/download/v4.115.0/code-server-4.115.0-linux-amd64.tar.gz

# Extract file
echo "[3/6] Mengekstrak file..."
tar -xzf code-server.tar.gz

# Pindahkan ke folder /opt
echo "[4/6] Memindahkan file ke /opt/code-server..."
sudo mv code-server-4.115.0-linux-amd64 /opt/code-server

# Bikin file service systemd
echo "[5/6] Membuat service systemctl..."
sudo tee /etc/systemd/system/code-server.service > /dev/null <<EOF
[Unit]
Description=Code Server Bro
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/code-server
Environment="PASSWORD=1"
ExecStart=/opt/code-server/bin/code-server --bind-addr 0.0.0.0:3030
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Aktifkan dan jalankan service
echo "[6/6] Mengaktifkan dan menjalankan service di background..."
sudo systemctl daemon-reload
sudo systemctl enable code-server
sudo systemctl restart code-server

# Bersihkan file zip yang udah nggak kepakai
rm -f code-server.tar.gz

echo "========================================="
echo "  Instalasi Beres Bro! Mantap!"
echo "  Code Server sekarang udah otomatis jalan."
echo "  Cek statusnya pakai: systemctl status code-server"
echo "========================================="
