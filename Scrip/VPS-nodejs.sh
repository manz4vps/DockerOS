const { spawn, execSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const readline = require('readline');

console.clear();
console.log("\x1b[36m╔══════════════════════════════════════════════════════════════════════════╗\x1b[0m");
console.log("\x1b[36m║ \x1b[35m\x1b[1m 🚀 PTERO-VM: V42 (UNIVERSAL COMPATIBILITY) 🚀                        \x1b[0m\x1b[36m ║\x1b[0m");
console.log("\x1b[36m║ \x1b[32m ✨ Smart Unzip (Python Fallback) • Anti-Bom • Clean Menu ✨          \x1b[0m\x1b[36m ║\x1b[0m");
console.log("\x1b[36m╚══════════════════════════════════════════════════════════════════════════╝\x1b[0m\n");

const cpuArch = os.arch(); 
let archName = 'x86_64';
if (cpuArch === 'arm64' || cpuArch === 'aarch64' || cpuArch === 'arm') archName = 'aarch64';

const LINK_PROOT = `https://github.com/ysdragon/proot-static/releases/download/v5.4.0/proot-${archName}-static`;

function bersihkanSistemLuar() {
    console.log("\x1b[33m[PROSES] Menghapus OS lama (index.js aman)...\x1b[0m");
    try { 
        execSync("find . -mindepth 1 -maxdepth 1 ! -name 'index.js' ! -name 'node_modules' -exec rm -rf {} +", { stdio: 'ignore' }); 
    } catch (e) {}
}

function rakitYsdragon() {
    console.log(`\x1b[34m[DOWNLOAD]\x1b[0m Mengambil Proot Ysdragon v5.4.0 (${archName})...`);
    try { execSync(`curl -L -s -o proot "${LINK_PROOT}"`); } catch(e){}

    console.log("\x1b[34m[DOWNLOAD]\x1b[0m Menyedot File Original Ysdragon...");
    try {
        execSync('curl -L -A "Mozilla/5.0" -s -o ysdragon.zip "https://github.com/ysdragon/Pterodactyl-VPS-Egg/archive/refs/heads/main.zip"');
        
        console.log("\x1b[33m[EKSTRAK]\x1b[0m Membongkar file (Menggunakan Smart Unzip)...");
        // 🌟 FITUR UTAMA V42: SMART EXTRACTOR (PYTHON BACKUP) 
        try {
            // Coba cara normal (unzip)
            execSync('unzip -o -q ysdragon.zip');
        } catch (e) {
            console.log("\x1b[31m[INFO] 'unzip' tidak ditemukan! Mencoba jalur Python...\x1b[0m");
            try {
                // Kalau gagal, pake Python (Jurus Hacker)
                execSync('python3 -m zipfile -e ysdragon.zip .');
            } catch (e2) {
                try {
                    // Coba python versi lama
                    execSync('python -m zipfile -e ysdragon.zip .');
                } catch (e3) {
                     // Coba bsdtar (biasanya ada di image minimalis)
                     try { execSync('bsdtar -xf ysdragon.zip'); } catch(e4) {
                        console.log("\x1b[31m[FATAL] Server ini parah banget! Gak ada unzip maupun python.\x1b[0m");
                        process.exit(1);
                     }
                }
            }
        }
        
        console.log("\x1b[33m[PROSES] Menyusun file system...\x1b[0m");
        execSync('cp -r Pterodactyl-VPS-Egg-main/scripts/* ./ 2>/dev/null || true');
        execSync('cp Pterodactyl-VPS-Egg-main/scripts/vnc/install.sh ./vnc_install.sh 2>/dev/null || true');
        execSync('rm -rf Pterodactyl-VPS-Egg-main ysdragon.zip scripts');

        console.log("\x1b[35m[PATCHING]\x1b[0m Menyuntikkan Anti-Bom & Obat Anti-Error...");
        
        let ep = fs.readFileSync('entrypoint.sh', 'utf8');
        ep = ep.replace(/\/usr\/local\/bin\/proot/g, '/home/container/proot');
        ep = ep.replace(/"\/install\.sh"/g, '"/home/container/install.sh"');
        ep = ep.replace(/sh \/helper\.sh/g, 'sh /home/container/helper.sh');
        ep = ep.replace(/MODIFIED_STARTUP=.*/g, 'MODIFIED_STARTUP="bash"'); 
        fs.writeFileSync('entrypoint.sh', ep);

        let hp = fs.readFileSync('helper.sh', 'utf8');
        hp = hp.replace(/\/usr\/local\/bin\/proot/g, '/home/container/proot');
        hp = hp.replace(/cp \/common\.sh/g, 'cp /home/container/common.sh');
        hp = hp.replace(/cp \/run\.sh/g, 'cp /home/container/run.sh');
        fs.writeFileSync('helper.sh', hp);

        // Anti-Bom Reinstall Ysdragon (AMAN!)
        let runSh = fs.readFileSync('run.sh', 'utf8');
        runSh = runSh.replace(/find \/ -mindepth 1 -xdev -delete.*/g, 'find / -mindepth 1 -maxdepth 1 ! -name "index.js" ! -name "node_modules" -exec rm -rf {} + > /dev/null 2>&1');
        fs.writeFileSync('run.sh', runSh);

        let inst = fs.readFileSync('install.sh', 'utf8');
        inst = inst.replace(/\. \/common\.sh/g, '. /home/container/common.sh');
        inst = inst.replace(/cp \/common\.sh \/run\.sh/g, 'cp /home/container/common.sh /home/container/run.sh');
        inst = inst.replace(/\[ -f "\/vnc_install\.sh" \]/g, '[ -f "/home/container/vnc_install.sh" ]');
        inst = inst.replace(/cp \/vnc_install\.sh/g, 'cp /home/container/vnc_install.sh');
        inst = inst.replace("echo \"$response\" | jq -e '.error' >/dev/null 2>&1", "echo \"$response\" | grep -q '\"error\"' >/dev/null 2>&1");
        inst = inst.replace("echo \"$response\" | jq -r '.label'", "echo \"$response\" | grep -o '\"label\":\"[^\"]*' | cut -d'\"' -f4");

        const aptBypass = `
    mkdir -p "$ROOTFS_DIR/etc/apt/apt.conf.d" 2>/dev/null || true
    echo 'APT::Get::AllowUnauthenticated "true";' > "$ROOTFS_DIR/etc/apt/apt.conf.d/99-pterovm" 2>/dev/null || true
    echo 'Acquire::AllowInsecureRepositories "true";' >> "$ROOTFS_DIR/etc/apt/apt.conf.d/99-pterovm" 2>/dev/null || true
    echo 'APT::Sandbox::User "root";' >> "$ROOTFS_DIR/etc/apt/apt.conf.d/99-pterovm" 2>/dev/null || true
    sed -i 's/^deb /deb [trusted=yes] /g' "$ROOTFS_DIR/etc/apt/sources.list" 2>/dev/null || true
    rm -rf "$ROOTFS_DIR/etc/apt/trusted.gpg.d/"* 2>/dev/null || true
        `;
        inst = inst.replace(/mkdir -p "\$ROOTFS_DIR\/home\/container\/"/g, aptBypass + '\n    mkdir -p "$ROOTFS_DIR/home/container/"');
        fs.writeFileSync('install.sh', inst);

        console.log("\x1b[32m[SUKSES] Sistem Ysdragon siap!\x1b[0m");
    } catch (e) {
        console.log("\x1b[31m[ERROR] Gagal merakit. Cek log diatas.\x1b[0m"); process.exit(1);
    }
}

function berikanIzinPenuh() {
    try {
        const files = fs.readdirSync('./');
        for (const f of files) {
            if (f.endsWith('.sh') || f === 'proot') fs.chmodSync(f, 0o777); 
        }
    } catch (e) {}
}

function jalankanYsdragon() {
    berikanIzinPenuh();
    const envPalsu = Object.assign({}, process.env, { STARTUP: "bash", HOME: "/home/container" });
    const child = spawn('bash', ['/home/container/entrypoint.sh'], { stdio: 'inherit', env: envPalsu });
    child.on('exit', (c) => console.log(`\n\x1b[33m[INFO] Server dimatikan. Silakan klik Restart di Panel.\x1b[0m`));
}

// === MENU KONTROL UTAMA ===
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

if (fs.existsSync('./entrypoint.sh') && fs.existsSync('./proot')) {
    console.log("\x1b[32m[SYSTEM] OS Ysdragon sudah terpasang!\x1b[0m");
    rl.question("\x1b[33mKetik 'masuk' (Enter) untuk jalankan OS, atau 'reset' untuk menghapus OS dari luar:\x1b[0m\n\x1b[36m> \x1b[0m", (ans) => {
        rl.close();
        if (ans.toLowerCase().trim() === 'reset') {
            bersihkanSistemLuar();
            console.log("\x1b[32m[SUCCESS] OS lama berhasil dihapus! (index.js AMAN). Silakan klik tombol Restart di panel.\x1b[0m");
            process.exit(0);
        } else {
            console.log("\x1b[32mMeluncur ke OS...\x1b[0m");
            jalankanYsdragon();
        }
    });
} else {
    // LANGSUNG PANGGIL YSDRAGON, GAK PAKE MENU NODE.JS LAGI!
    console.log("\x1b[33m[INFO] Sistem belum terpasang. Menyiapkan instalasi asli Ysdragon...\x1b[0m");
    rakitYsdragon();
    jalankanYsdragon();
}
