true /*
# ====================================================
# [ BAGIAN 1: SCRIPT BASH UNTUK VPS ]
# (Node.js akan menganggap bagian ini sebagai komentar)
# ====================================================

FRP_VERSION="0.54.0"
CONFIG_FILE="/etc/frp/frpc.ini"
SERVICE_FILE="/etc/systemd/system/frpc.service"

echo "====================================================="
echo "      🚀 SETUP FRP TUNNEL (MODE: VPS BASH) 🚀        "
echo "====================================================="

# Animasi Spinner
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid 2>/dev/null)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "      \b\b\b\b\b\b"
}

if [ -f "$CONFIG_FILE" ]; then
    PTERO_IP=$(grep -m 1 '^server_addr' $CONFIG_FILE | awk '{print $3}')
    TUNNEL_PORT=$(grep -m 1 '^server_port' $CONFIG_FILE | awk '{print $3}')
    MC_PORT=$(grep -m 1 '^local_port' $CONFIG_FILE | awk '{print $3}')

    echo "[ INFO ] FRP TUNNEL SUDAH TERINSTALL!"
    echo "Konfigurasi saat ini:"
    echo "- IP Pterodactyl : $PTERO_IP"
    echo "- Port Tunnel    : $TUNNEL_PORT"
    echo "- Port Join MC   : $MC_PORT"
    echo "====================================================="
    
    read -p "Ingin mengubah konfigurasi? (y/n): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        read -p "Masukkan IP Pterodactyl baru : " PTERO_IP
        read -p "Masukkan Port Tunnel baru    : " TUNNEL_PORT
        read -p "Masukkan Port Join MC baru   : " MC_PORT
        
        cat <<CONFIG | sudo tee $CONFIG_FILE > /dev/null
[common]
server_addr = ${PTERO_IP}
server_port = ${TUNNEL_PORT}

[minecraft_java_tcp]
type = tcp
local_ip = 127.0.0.1
local_port = ${MC_PORT}
remote_port = ${MC_PORT}

[minecraft_bedrock_udp]
type = udp
local_ip = 127.0.0.1
local_port = ${MC_PORT}
remote_port = ${MC_PORT}
CONFIG
        sudo systemctl restart frpc
        echo "[ SUCCESS ] SETTINGAN BERHASIL DIUPDATE!"
    else
        echo "[ SUCCESS ] Melanjutkan tanpa perubahan."
    fi
    exit 0
fi

# SETUP BARU VPS
read -p "[ INPUT ] Masukkan IP Panel Pterodactyl : " PTERO_IP
read -p "[ INPUT ] Masukkan Port Tunnel Utama    : " TUNNEL_PORT
read -p "[ INPUT ] Masukkan Port Join MC         : " MC_PORT
echo ""

ARCH=$(uname -m)
case "$ARCH" in
    x86_64) FRP_ARCH="amd64" ;;
    aarch64|arm64) FRP_ARCH="arm64" ;;
    armv7l|armv6l|armv8l) FRP_ARCH="arm" ;;
    i386|i686) FRP_ARCH="386" ;;
    mips64) FRP_ARCH="mips64" ;;
    *) FRP_ARCH="amd64" ;;
esac

echo -n "[ INFO ] Mendownload FRP Client (${FRP_ARCH})..."
wget -q https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz &
spinner $!
echo " Done."

echo -n "[ INFO ] Mengekstrak file..."
tar -zxf frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz &
spinner $!
sudo mkdir -p /etc/frp
sudo mv frp_${FRP_VERSION}_linux_${FRP_ARCH}/frpc /usr/local/bin/frpc
sudo chmod +x /usr/local/bin/frpc
echo " Done."

echo -n "[ INFO ] Membersihkan sampah..."
rm -rf frp_${FRP_VERSION}_linux_${FRP_ARCH}.tar.gz frp_${FRP_VERSION}_linux_${FRP_ARCH} &
spinner $!
echo " Done."

echo -n "[ INFO ] Membuat konfigurasi..."
cat <<CONFIG | sudo tee $CONFIG_FILE > /dev/null
[common]
server_addr = ${PTERO_IP}
server_port = ${TUNNEL_PORT}

[minecraft_java_tcp]
type = tcp
local_ip = 127.0.0.1
local_port = ${MC_PORT}
remote_port = ${MC_PORT}

[minecraft_bedrock_udp]
type = udp
local_ip = 127.0.0.1
local_port = ${MC_PORT}
remote_port = ${MC_PORT}
CONFIG
echo " Done."

echo -n "[ INFO ] Membuat Systemd Service..."
cat <<SVC | sudo tee $SERVICE_FILE > /dev/null
[Unit]
Description=FRP Client Auto-Start
After=network.target network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/local/bin/frpc -c /etc/frp/frpc.ini
Restart=always
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
SVC
sudo systemctl daemon-reload
sudo systemctl enable frpc > /dev/null 2>&1
sudo systemctl restart frpc
echo " Done."

echo "====================================================="
echo "[ SUCCESS ] SETUP ALL-IN-ONE VPS SELESAI!"
echo "Tunnel berjalan permanen di background."
echo "====================================================="

# Ini penting biar VPS gak baca kode Node.js di bawahnya
exit 0
*/

// ====================================================
// [ BAGIAN 2: SCRIPT NODE.JS UNTUK PTERODACTYL ]
// (Terminal Bash tidak akan pernah sampai ke bagian ini)
// ====================================================

const { execSync, spawn } = require('child_process');
const fs = require('fs');
const os = require('os');

const FRP_VERSION = "0.54.0";
const cpuArch = os.arch();
let frpArch = "amd64"; 

if (cpuArch === 'x64') frpArch = 'amd64';
else if (cpuArch === 'arm64' || cpuArch === 'aarch64') frpArch = 'arm64';
else if (cpuArch === 'arm') frpArch = 'arm';
else if (cpuArch === 'ia32') frpArch = '386';
else if (cpuArch === 'mips64') frpArch = 'mips64';
else if (cpuArch === 'mips64el') frpArch = 'mips64le';
else frpArch = cpuArch; 

const FILE_NAME = `frp_${FRP_VERSION}_linux_${frpArch}.tar.gz`;
const DIR_NAME = `frp_${FRP_VERSION}_linux_${frpArch}`;
const CONFIG_FILE = 'frps.ini';

console.log("=====================================================");
console.log("    🚀 SETUP FRP SERVER (MODE: PTERODACTYL) 🚀       ");
console.log(`[ INFO ] CPU: ${cpuArch} -> Versi FRP: ${frpArch}`);
console.log("=====================================================");

function simpanConfig(port) {
    const iniContent = `[common]\nbind_port = ${port}\n`;
    fs.writeFileSync(CONFIG_FILE, iniContent);
    console.log(`[ SUCCESS ] Konfigurasi disimpan (Port: ${port}).`);
}

function lanjutkanSetup(port) {
    console.log("\n[ INFO ] Memulai Proses FRP...");
    if (!fs.existsSync('./frps')) {
        console.log(`[ INFO ] Mendownload FRP Server (${frpArch})...`);
        try {
            execSync(`curl -sL https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/${FILE_NAME} -o ${FILE_NAME}`);
            console.log("[ INFO ] Mengekstrak file...");
            execSync(`tar -zxf ${FILE_NAME}`);
            execSync(`mv ${DIR_NAME}/frps ./frps`);
            console.log("[ INFO ] Membersihkan file sampah...");
            execSync(`rm -rf ${FILE_NAME} ${DIR_NAME}`);
        } catch (err) {
            console.log("[ ERROR ] Gagal mendownload/mengekstrak FRP. Cek koneksi internet.");
            process.exit(1);
        }
    }
    
    execSync('chmod +x ./frps');
    console.log(`[ RUN ] Menjalankan Tunnel di port ${port}...`);
    const frps = spawn('./frps', ['-c', `./${CONFIG_FILE}`]);

    frps.stdout.on('data', (data) => process.stdout.write(`[ FRP ] ${data}`));
    frps.stderr.on('data', (data) => process.stderr.write(`[ ERR ] ${data}`));

    setInterval(() => {}, 1000 * 60 * 60);
}

process.stdin.setEncoding('utf-8');
let isFirstRun = !fs.existsSync(CONFIG_FILE);
let step = isFirstRun ? 'ASK_PORT' : 'ASK_CHANGE';
let savedPort = null;

if (isFirstRun) {
    console.log("[ WARNING ] INI PERTAMA KALI MENJALANKAN SCRIPT");
    console.log("[ PROMPT ] Masukkan Port Tunnel Utama:");
} else {
    try {
        const configContent = fs.readFileSync(CONFIG_FILE, 'utf-8');
        const match = configContent.match(/bind_port\s*=\s*(\d+)/);
        savedPort = match ? match[1] : null;
    } catch (e) { savedPort = null; }
    
    console.log(`[ INFO ] Port Tunnel saat ini: ${savedPort}`);
    console.log("[ PROMPT ] Ganti port tunnel? (y/n): ");
}

process.stdin.on('data', (data) => {
    let input = data.trim();
    if (step === 'DONE') return;

    if (step === 'ASK_PORT') {
        if (input && !isNaN(input)) {
            console.log(`\n[ SUCCESS ] Port diset ke: ${input}`);
            simpanConfig(input);
            step = 'DONE';
            lanjutkanSetup(input);
        } else {
            console.log("\n[ ERROR ] Port harus angka!");
            console.log("[ PROMPT ] Masukkan Port Tunnel:");
        }
    } else if (step === 'ASK_CHANGE') {
        if (input.toLowerCase() === 'y') {
            console.log("\n[ PROMPT ] Masukkan Port Tunnel baru:");
            step = 'ASK_NEW_PORT';
        } else {
            console.log("\n[ SUCCESS ] Menggunakan port lama.");
            step = 'DONE';
            lanjutkanSetup(savedPort);
        }
    } else if (step === 'ASK_NEW_PORT') {
         if (input && !isNaN(input)) {
            console.log(`\n[ SUCCESS ] Port diganti ke: ${input}`);
            simpanConfig(input);
            step = 'DONE';
            lanjutkanSetup(input);
        } else {
            console.log("\n[ ERROR ] Port harus angka!");
            console.log("[ PROMPT ] Masukkan Port Tunnel baru:");
        }
    }
});
