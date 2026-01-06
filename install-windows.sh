install_firefox_in_container() {
    local container_name="$1"
    echo "========================================="
    echo "🚀 Menginstall Firefox & Setting Auto-Start (Mode Paksa)..."
    echo "========================================="
    
    docker exec -t "$container_name" /bin/bash -c '
    # --- BAGIAN 1: INSTALL (SAMA KAYAK TADI KARENA UDAH WORK) ---
    rm -f /etc/apt/sources.list.d/google-chrome.list
    apt-get update
    apt-get install -y software-properties-common
    add-apt-repository -y ppa:mozillateam/ppa
    
    echo "
Package: firefox*
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001
" > /etc/apt/preferences.d/mozilla-firefox

    apt-get update
    apt-get install -y firefox

    # --- BAGIAN 2: BIKIN SHORTCUT DESKTOP (BIAR BISA KLIK MANUAL) ---
    rm -f /root/Desktop/*.desktop
    mkdir -p /root/Desktop
    
    cat <<EOF > /root/Desktop/firefox.desktop
[Desktop Entry]
Type=Application
Name=Firefox Browser
Exec=firefox --no-sandbox
Icon=firefox
Terminal=false
StartupNotify=false
EOF
    chmod +x /root/Desktop/firefox.desktop
    chown -R root:root /root/Desktop

    # --- BAGIAN 3: AUTOSTART "BRUTAL FORCE" (INI FIX NYA) ---
    
    # 1. Kita buat script peluncur khusus yang ada jeda waktunya
    cat <<EOF > /usr/bin/force-start-firefox.sh
#!/bin/bash
# Tunggu 15 detik biar Desktop LXDE loading 100% dulu
sleep 15
# Set Display ke :1 (Default VNC)
export DISPLAY=:1
# Jalankan Firefox mode no-sandbox (background process)
nohup firefox --no-sandbox > /dev/null 2>&1 &
EOF

    chmod +x /usr/bin/force-start-firefox.sh

    # 2. Kita suntikkan langsung ke jantung pengaturan LXDE
    # File ini dibaca saat LXDE loading. Kita suruh dia jalanin script kita.
    LXDE_CONFIG="/etc/xdg/lxsession/LXDE/autostart"
    
    # Hapus baris lama kalau ada biar gak dobel
    sed -i "/force-start-firefox.sh/d" \$LXDE_CONFIG
    
    # Tambahkan perintah baru di baris paling bawah
    echo "@bash /usr/bin/force-start-firefox.sh" >> \$LXDE_CONFIG

    echo "✅ Inject Auto-Start ke LXDE Config Berhasil."
    '
    
    echo "========================================="
    echo "✅ Firefox Siap."
    echo "👉 Pilih menu '5. Reset Container' sekarang!"
    echo "👉 PENTING: Pas buka VNC, JANGAN APA-APAIN DULU."
    echo "👉 Tunggu sekitar 15-20 detik, Firefox bakal loncat keluar sendiri."
    echo "========================================="
}
