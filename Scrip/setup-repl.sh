#!/bin/bash

echo "======================================"
echo "   PANEL V26 - AUTO SETUP SCRIPT"
echo "======================================"
echo ""

# ── 1. Download File Zip ──────────────────
echo "[1/5] Mendownload panel.zip..."

ZIP_URL="https://github.com/manz4vps/Panel-By-Manz4Vps/raw/refs/heads/main/panel.zip"

curl -L -o panel.zip "$ZIP_URL"
if [ $? -ne 0 ]; then
  echo "ERROR: Gagal mendownload panel.zip!"
  exit 1
fi
echo "OK panel.zip berhasil didownload."
echo ""

# ── 2. Ekstrak File Zip ───────────────────
echo "[2/5] Mengekstrak file ke workspace..."

unzip -o panel.zip
if [ $? -ne 0 ]; then
  echo "ERROR: Gagal mengekstrak panel.zip! Pastikan file zip tidak korup."
  exit 1
fi

rm panel.zip

# Verifikasi: Cek apakah file wajib ada setelah diekstrak
for FILE in index.js package.json; do
  if [ -f "$FILE" ]; then
    echo "  OK $FILE tersedia."
  else
    echo "ERROR: File $FILE tidak ditemukan setelah diekstrak! Pastikan letaknya tidak di dalam sub-folder saat kamu membuat panel.zip."
    exit 1
  fi
done

echo "OK File berhasil diekstrak dan siap."
echo ""

# ── 3. Install Node.js + npm packages ─────
echo "[3/5] Menginstall npm packages..."

if ! command -v npm &> /dev/null; then
  echo "  npm tidak ditemukan, mendownload Node.js binary langsung..."
  NODE_VERSION="20.18.0"
  NODE_TAR="/tmp/node-v${NODE_VERSION}-linux-x64.tar.xz"
  NODE_DIR="/tmp/node-v${NODE_VERSION}-linux-x64"

  curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o "$NODE_TAR"
  if [ $? -ne 0 ]; then
    echo "ERROR: Gagal download Node.js binary!"
    exit 1
  fi

  tar -xf "$NODE_TAR" -C /tmp/
  if [ $? -ne 0 ]; then
    echo "ERROR: Gagal ekstrak Node.js!"
    exit 1
  fi

  export PATH="$NODE_DIR/bin:$PATH"

  if ! command -v npm &> /dev/null; then
    echo "ERROR: npm masih tidak ditemukan setelah install!"
    exit 1
  fi
  echo "  Node.js $(node -v) berhasil diinstall."
fi

npm install
if [ $? -ne 0 ]; then
  echo "  npm install gagal, mencoba dengan --legacy-peer-deps..."
  npm install --legacy-peer-deps
  if [ $? -ne 0 ]; then
    echo "ERROR: Gagal install npm packages!"
    exit 1
  fi
fi
echo "OK NPM packages berhasil diinstall."
echo ""

# ── 4. Setup replit.nix & .replit ─────────
echo "[4/5] Menulis konfigurasi Replit..."

if cat > replit.nix << 'EOF'
{pkgs}: {
  deps = [
    pkgs.xorg.libX11
    pkgs.xorg.libXext
    pkgs.xorg.libXrender
    pkgs.xorg.libXtst
    pkgs.xorg.libXi
  ];
}
EOF
then
  echo "  OK replit.nix berhasil ditulis."
else
  echo "  SKIP replit.nix (diblokir Replit, tidak masalah)."
fi

if cat > .replit << 'EOF'
modules = ["nodejs-20"]

[nix]
channel = "stable-25_05"

[workflows]
runButton = "Project"

[[workflows.workflow]]
name = "Project"
mode = "parallel"
author = "agent"

[[workflows.workflow.tasks]]
task = "workflow.run"
args = "Start application"

[[workflows.workflow]]
name = "Start application"
author = "agent"

[[workflows.workflow.tasks]]
task = "shell.exec"
args = "node index.js"
waitForPort = 5000

[workflows.workflow.metadata]
outputType = "webview"

[[ports]]
localPort = 5000
externalPort = 80
EOF
then
  echo "  OK .replit berhasil ditulis."
else
  echo "  SKIP .replit (diblokir Replit, workflow sudah dikonfigurasi otomatis)."
fi

echo "OK Langkah konfigurasi selesai."
echo ""

echo "======================================"
echo "   SETUP SELESAI!"
echo "======================================"
echo ""
echo "Panel V26 siap dijalankan."
echo "Tekan tombol Run di Replit untuk mulai."
echo ""
