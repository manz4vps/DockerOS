#!/bin/bash
# ================================================
# TAILSCALE FUNNEL PORT MANAGER SCRIPT BY MANZ
# Otomatis IP Angka & Random Public Port
# ================================================

# --- FUNGSI-FUNGSI PENTING ---

# 1. Mendapatkan IP v4 Tailscale (Yang angka, bukan domain)
get_ts_ip() {
    # Menggunakan perintah bawaan tailscale untuk ambil IP
    ts_ip=$(tailscale ip -4)
    if [ -z "$ts_ip" ]; then
        echo "❌ Error: Tidak bisa mendapatkan IP Tailscale."
        echo "Pastikan Tailscale sudah 'up' dan konek internet."
        exit 1
    fi
    echo "$ts_ip"
}

# 2. Generate Random Port Tinggi (Range 20000 - 60000)
# Catatan: Port TCP maksimal hanya sampai 65535.
generate_random_port() {
    shuf -i 20000-60000 -n 1
}

# 3. Fungsi Tambah Port Baru
add_new_port() {
    clear
    echo "=== TAMBAH PORT FORWARDING BARU ==="
    my_ip=$(get_ts_ip)
    
    echo -n "Masukkan PORT LOCAL server kamu (contoh: 25256): "
    read local_port

    # Validasi input harus angka
    if ! [[ "$local_port" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: Input harus berupa angka port!"
        read -p "Tekan Enter untuk kembali..."
        return
    fi

    # Generate public port acak
    public_port=$(generate_random_port)

    echo ""
    echo "Sedang memproses..."
    echo "⚙️  Public Port (Random): $public_port"
    echo "🏠 Local Port (Server): $local_port"
    echo "Menjalankan Tailscale Funnel..."

    # === INI PERINTAH UTAMANYA ===
    # Menjalankan funnel di background (--bg)
    # Mengarahkan port publik acak ke port lokal pilihanmu
    sudo tailscale funnel --bg --tcp $public_port localhost:$local_port
    
    status_cmd=$?

    if [ $status_cmd -eq 0 ]; then
        clear
        echo "✅ SUKSES! PORT BERHASIL DIBUKA."
        echo "=================================================="
        echo "KASIH ALAMAT INI KE TEMAN MABAR (Pakai IP Angka):"
        echo ""
        echo "👉  $my_ip:$public_port  👈"
        echo ""
        echo "=================================================="
        echo "Note: Server localmu harus jalan di port $local_port"
    else
        echo ""
        echo "❌ GAGAL menjalankan funnel. Cek log error di atas."
    fi
    read -p "Tekan Enter untuk kembali ke menu..."
}

# 4. Fungsi Stop Port Tertentu
stop_specific_port() {
    clear
    echo "=== STOP PORT TERTENTU ==="
    echo "Status saat ini:"
    # Tampilkan hanya baris yang mengandung 'tcp://' biar rapi
    tailscale funnel status | grep "tcp://"
    echo "---------------------------------"
    echo -n "Masukkan PUBLIC PORT yang ingin dimatikan (angka depan): "
    read port_to_stop

    if ! [[ "$port_to_stop" =~ ^[0-9]+$ ]]; then
        echo "❌ Error: Input harus angka."
        read -p "Enter untuk kembali..."
        return
    fi

    echo "Mematikan funnel di port $port_to_stop..."
    sudo tailscale funnel --tcp=$port_to_stop off
    echo "Selesai."
    read -p "Tekan Enter untuk kembali..."
}

# 5. Fungsi Reset Total
reset_all() {
    clear
    echo "⚠️  PERINGATAN KERAS ⚠️"
    echo "Ini akan MENGHAPUS SEMUA port forwarding yang aktif."
    echo "Semua temanmu akan terputus."
    echo -n "Yakin ingin RESET SEMUA? (ketik 'y' untuk ya): "
    read confirm
    if [ "$confirm" == "y" ]; then
        echo "Mereset total konfigurasi serve..."
        sudo tailscale serve reset
        echo "✅ Semua konfigurasi telah dibersihkan."
    else
        echo "Batal."
    fi
    read -p "Tekan Enter untuk kembali..."
}

# --- MENU UTAMA ---
while true; do
    clear
    current_ip=$(get_ts_ip)
    echo "========================================"
    echo "   🤖 TAILSCALE PORT MANAGER BY MANZ 🤖"
    echo "   IP Anda: $current_ip"
    echo "========================================"
    echo "1. ➕ Tambah Port Baru (Random Public -> Local)"
    echo "2. 📜 Lihat Status Port Aktif"
    echo "3. 🛑 Stop Port Tertentu"
    echo "4. ♻️  RESET SEMUA PORT (Hapus Total)"
    echo "5. 🚪 Keluar"
    echo "========================================"
    echo -n "Pilih menu (1-5): "
    read choice

    case $choice in
        1) add_new_port ;;
        2) clear; tailscale funnel status; read -p "Enter untuk kembali..." ;;
        3) stop_specific_port ;;
        4) reset_all ;;
        5) echo "Bye bye bro!"; exit 0 ;;
        *) echo "Pilihan salah bro."; sleep 1 ;;
    esac
done
