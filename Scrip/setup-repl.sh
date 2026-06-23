#!/bin/bash

echo "======================================"
echo "   PANEL V26 - AUTO SETUP SCRIPT"
echo "======================================"
echo ""

# ── Secret key PlayIt (sudah di-claim, langsung pakai) ──
PLAYIT_SECRET_KEY="5c91211aa5efd464f13a527f52143b8916e634c4e15b3acf4db9cb0c31bf6b57"

# ── 1. Download File Zip ──────────────────
echo "[1/7] Mendownload panel.zip..."

# GANTI URL DI BAWAH dengan link RAW github kamu yang mengarah langsung ke panel.zip
ZIP_URL="https://github.com/manz4vps/Panel-By-Manz4Vps/raw/refs/heads/main/panel.zip"

curl -L -o panel.zip "$ZIP_URL"
if [ $? -ne 0 ]; then
  echo "ERROR: Gagal mendownload panel.zip!"
  exit 1
fi
echo "OK panel.zip berhasil didownload."
echo ""

# ── 2. Ekstrak File Zip ───────────────────
echo "[2/7] Mengekstrak file ke workspace..."

# Mengekstrak zip dan menimpa file jika sudah ada (-o)
unzip -o panel.zip
if [ $? -ne 0 ]; then
  echo "ERROR: Gagal mengekstrak panel.zip! Pastikan file zip tidak korup."
  exit 1
fi

# Menghapus file zip agar workspace bersih
rm panel.zip

# Verifikasi: Cek apakah file wajib ada setelah diekstrak
for FILE in index.js package.json cloudflare.cjs; do
  if [ -f "$FILE" ]; then
    echo "  OK $FILE tersedia."
  else
    echo "ERROR: File $FILE tidak ditemukan setelah diekstrak! Pastikan letaknya tidak di dalam sub-folder saat kamu membuat panel.zip."
    exit 1
  fi
done

echo "OK File berhasil diekstrak dan siap."
echo ""

# ── 3. Patch port 443 → 5000 ──────────────
echo "[3/7] Mengubah port ke 5000..."
if grep -q "const PTERO_PORT = 443;" index.js; then
  sed -i 's/const PTERO_PORT = 443;/const PTERO_PORT = process.env.PORT || 5000;/' index.js
  echo "OK Port berhasil diubah ke 5000."
else
  echo "  INFO: String 'const PTERO_PORT = 443;' tidak ditemukan di index.js, skip patch port."
fi
echo ""

# ── 4. Install Node.js + npm packages ─────
echo "[4/7] Menginstall npm packages..."

# Cek apakah node/npm sudah ada
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

# ── 5. Download PlayIt ────────────────────
echo "[5/7] Mendownload PlayIt tunnel agent..."
curl -sL https://github.com/playit-cloud/playit-agent/releases/download/v0.15.26/playit-linux-amd64 -o playit_old
if [ $? -ne 0 ]; then
  echo "ERROR: Gagal download PlayIt!"
  exit 1
fi
chmod +x playit_old
echo "OK PlayIt berhasil didownload."
echo ""

# ── 6. Setup replit.nix & .replit ─────────
echo "[6/7] Menulis konfigurasi Replit..."

# replit.nix
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

# .replit
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

[[workflows.workflow.tasks]]
task = "workflow.run"
args = "PlayIt Tunnel"

[[workflows.workflow]]
name = "Start application"
author = "agent"

[[workflows.workflow.tasks]]
task = "shell.exec"
args = "node index.js"
waitForPort = 5000

[workflows.workflow.metadata]
outputType = "webview"

[[workflows.workflow]]
name = "PlayIt Tunnel"
author = "agent"

[[workflows.workflow.tasks]]
task = "shell.exec"
args = "bash -c 'set -a; [ -f .env ] && source .env; set +a; while true; do ./playit_old --secret $PLAYIT_SECRET start; echo \"[PlayIt] Tunnel putus, restart dalam 5 detik...\"; sleep 5; done'"

[workflows.workflow.metadata]
outputType = "console"

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

# ── 7. Simpan PLAYIT_SECRET ke environment ─
echo "[7/7] Menyimpan PLAYIT_SECRET..."
export PLAYIT_SECRET="$PLAYIT_SECRET_KEY"

# Buat .env jika belum ada
if [ ! -f ".env" ]; then
  touch .env
fi

# Simpan ke .env supaya tersedia saat workflow jalan
if grep -q "PLAYIT_SECRET" .env 2>/dev/null; then
  sed -i "s/PLAYIT_SECRET=.*/PLAYIT_SECRET=$PLAYIT_SECRET_KEY/" .env
else
  echo "" >> .env
  echo "PLAYIT_SECRET=$PLAYIT_SECRET_KEY" >> .env
fi

echo "OK PLAYIT_SECRET berhasil disimpan."
echo ""

echo "======================================"
echo "   SETUP SELESAI!"
echo "======================================"
echo ""
echo "Panel V26 + PlayIt siap dijalankan."
echo "Tekan tombol Run di Replit untuk mulai."
echo "PlayIt akan auto-restart jika tunnel putus."
echo ""
