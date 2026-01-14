#!/bin/bash

# Target File Config SSH
CONFIG_FILE="/etc/ssh/sshd_config"

echo "[*] Memulai konfigurasi SSH..."

# Step 1: Backup config asli (jaga-jaga error)
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"
fi

# Step 2: Paksa PermitRootLogin menjadi 'yes'
# Menghapus baris lama jika ada, lalu memastikan settingan 'yes' aktif
sed -i 's/^#PermitRootLogin.*/PermitRootLogin yes/' "$CONFIG_FILE"
# Cek apakah barisnya sudah benar, kalau belum tambahkan manual
grep -q "^PermitRootLogin yes" "$CONFIG_FILE" || echo "PermitRootLogin yes" >> "$CONFIG_FILE"

# Step 3: Paksa PasswordAuthentication menjadi 'yes'
# Hapus semua baris PasswordAuthentication lama (baik yg di-comment atau tidak)
sed -i '/^#PasswordAuthentication/d' "$CONFIG_FILE"
sed -i '/^PasswordAuthentication/d' "$CONFIG_FILE"
# Tambahkan baris baru yang bersih
echo "PasswordAuthentication yes" >> "$CONFIG_FILE"

# Step 4: Restart SSH service
echo "[*] Restarting SSH service..."
# Cek service manager (systemctl atau service biasa)
if command -v systemctl &> /dev/null; then
    systemctl restart ssh || systemctl restart sshd
else
    service ssh restart || service sshd restart
fi

# Step 5: LANGSUNG Ganti Password Root
echo ""
echo "=================================================="
echo "   SILAKAN KETIK PASSWORD BARU UNTUK ROOT         "
echo "   (Ketik password -> Enter -> Ulangi -> Enter)   "
echo "=================================================="
echo ""

# Perintah ini akan langsung meminta inputmu
clear
passwd root

echo ""
echo "✅ SELESAI! Root login sudah aktif dengan password baru."
