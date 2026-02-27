#!/bin/bash

echo "Mulai proses instalasi..."

# 1. Update sistem dan install package dasar
apt update -y
apt install -y wget python3 curl sudo

# 2. Install NVM dan Node.js versi 24
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 24

# Cek versi untuk memastikan berhasil
echo "Versi Node.js dan NPM:"
node -v
nvm current
npm -v

# 3. Setup Systemctl replacement (Khusus buat di dalam Container/VPS yang nggak support systemd)
curl -o /bin/systemctl https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker/systemctl3.py
chmod +x /bin/systemctl

# 4. Install PufferPanel
curl -s https://packagecloud.io/install/repositories/pufferpanel/pufferpanel/script.deb.sh | bash
apt-get install pufferpanel -y

# 5. Jalankan PufferPanel
systemctl enable pufferpanel
systemctl start pufferpanel

# 6. Buat Akun Admin PufferPanel
pufferpanel user add --name manzxd --password manzxd --email manzxd@gmail.com --admin

echo "Mantap bro, instalasi PufferPanel dan Node.js selesai!"
