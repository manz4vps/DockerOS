#!/bin/bash

echo "========================================="
echo "  Mulai Setup Code Server Auto-Restart"
echo "========================================="

cd ~

echo "[1/7] Mengambil versi terbaru dari GitHub..."
LATEST=$(curl -s https://api.github.com/repos/coder/code-server/releases/latest | grep tag_name | cut -d '"' -f 4)

if [ -z "$LATEST" ]; then
  echo "Gagal mengambil versi terbaru!"
  exit 1
fi

echo "Versi terbaru: $LATEST"

echo "[2/7] Membersihkan file lama..."
sudo rm -rf code-server-*-linux-amd64
sudo rm -f code-server.tar.gz
sudo rm -rf /opt/code-server

echo "[3/7] Mendownload Code Server $LATEST..."
curl -L -o code-server.tar.gz https://github.com/coder/code-server/releases/download/$LATEST/code-server-$LATEST-linux-amd64.tar.gz

echo "[4/7] Mengekstrak file..."
tar -xzf code-server.tar.gz

echo "[5/7] Memindahkan ke /opt/code-server..."
sudo mv code-server-$LATEST-linux-amd64 /opt/code-server

echo "[6/7] Membuat service systemctl..."
sudo tee /etc/systemd/system/code-server.service > /dev/null <<EOF
[Unit]
Description=Code Server Bro
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/code-server
Environment="PASSWORD=manzxd"
ExecStart=/opt/code-server/bin/code-server --bind-addr 0.0.0.0:3030
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

echo "[7/7] Mengaktifkan dan menjalankan service..."
sudo systemctl daemon-reload
sudo systemctl enable code-server
sudo systemctl restart code-server

rm -f code-server.tar.gz

echo "========================================="
echo "  Instalasi Beres Bro! 🔥"
echo "  Versi terinstall: $LATEST"
echo "  Akses: http://IP:3030"
echo "========================================="
