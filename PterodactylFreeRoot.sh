const https = require("https");
const fs = require("fs");
const path = require("path");
const { spawn, spawnSync } = require("child_process");
const readline = require("readline");

const BASE = __dirname;
const PROOT = path.join(BASE, "proot");
const LAST_DISTRO_FILE = path.join(BASE, ".last-distro");
const IMAGE_SERVER = "https://images.linuxcontainers.org";

// =====================================
// DETEKSI ARSITEKTUR
// =====================================

const ARCH_MAP = {
    x64: "amd64",
    amd64: "amd64",
    arm64: "arm64",
    aarch64: "arm64",
    arm: "armhf",
    armhf: "armhf",
    armv7l: "armhf",
    ia32: "i386",
    i386: "i386",
    x86: "i386"
};

function detectArchitecture() {
    const candidates = [
        process.arch,
        process.env.HOSTTYPE,
        process.env.ARCH
    ];

    for (const candidate of candidates) {
        if (!candidate) continue;

        const normalized = String(candidate).toLowerCase().trim();

        if (ARCH_MAP[normalized]) {
            return ARCH_MAP[normalized];
        }
    }

    try {
        const result = spawnSync("uname", ["-m"], {
            encoding: "utf8"
        });

        if (result.status === 0) {
            const machine = result.stdout.trim().toLowerCase();

            if (ARCH_MAP[machine]) {
                return ARCH_MAP[machine];
            }
        }
    } catch {}

    return null;
}

const ARCH = detectArchitecture();

if (!ARCH) {
    console.log("Arsitektur tidak didukung!");
    process.exit(1);
}

// =====================================
// DAFTAR DISTRO
// =====================================

const DISTROS = {
    debian: [
        { name: "Debian 13 Trixie", distro: "debian", version: "trixie", id: "debian13" },
        { name: "Debian 12 Bookworm", distro: "debian", version: "bookworm", id: "debian12" },
        { name: "Debian 11 Bullseye", distro: "debian", version: "bullseye", id: "debian11" },
        { name: "Debian 10 Buster", distro: "debian", version: "buster", id: "debian10" }
    ],

    ubuntu: [
        { name: "Ubuntu 26.04 Resolute", distro: "ubuntu", version: "resolute", id: "ubuntu26" },
        { name: "Ubuntu 24.04 Noble", distro: "ubuntu", version: "noble", id: "ubuntu24" },
        { name: "Ubuntu 22.04 Jammy", distro: "ubuntu", version: "jammy", id: "ubuntu22" },
        { name: "Ubuntu 20.04 Focal", distro: "ubuntu", version: "focal", id: "ubuntu20" }
    ]
};

const ALL_DISTROS = [
    ...DISTROS.debian,
    ...DISTROS.ubuntu
];

const ROOTFS_CACHE = new Map();

// =====================================
// INPUT MENU
// =====================================

function ask(question) {
    return new Promise(resolve => {
        const rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });

        rl.question(question + " ", answer => {
            rl.close();
            resolve(answer.trim());
        });
    });
}

function clearTerminal() {
    process.stdout.write("\x1Bc");
}

function fakeEnter() {
    process.stdout.write("\r\n");
}

// =====================================
// HTTP REQUEST
// =====================================

function request(url, redirects = 10, method = "GET") {
    return new Promise((resolve, reject) => {
        let parsed;

        try {
            parsed = new URL(url);
        } catch (error) {
            return reject(error);
        }

        if (parsed.protocol !== "https:") {
            return reject(new Error("URL harus menggunakan HTTPS."));
        }

        const req = https.request(parsed, {
            method,
            headers: {
                "User-Agent": "Linux-Rootfs-Installer/3.0"
            },
            timeout: 60000
        }, res => {
            if ([301, 302, 303, 307, 308].includes(res.statusCode)) {
                const location = res.headers.location;
                res.resume();

                if (!redirects || !location) {
                    return reject(new Error("Redirect gagal."));
                }

                return resolve(
                    request(
                        new URL(location, url).href,
                        redirects - 1,
                        method
                    )
                );
            }

            if (res.statusCode < 200 || res.statusCode >= 300) {
                res.resume();
                return reject(new Error("HTTP " + res.statusCode + ": " + url));
            }

            resolve(res);
        });

        req.on("timeout", () => {
            req.destroy(new Error("Koneksi timeout."));
        });

        req.on("error", reject);
        req.end();
    });
}

// =====================================
// DOWNLOAD
// =====================================

async function download(url, destination) {
    console.log("\n================================");
    console.log("MEMULAI DOWNLOAD");
    console.log("================================");
    console.log(url);

    const response = await request(url);

    await new Promise((resolve, reject) => {
        const file = fs.createWriteStream(destination);

        response.pipe(file);

        file.on("finish", () => {
            file.close(resolve);
        });

        file.on("error", error => {
            fs.rmSync(destination, { force: true });
            reject(error);
        });

        response.on("error", error => {
            file.destroy();
            fs.rmSync(destination, { force: true });
            reject(error);
        });
    });

    if (
        !fs.existsSync(destination) ||
        fs.statSync(destination).size === 0
    ) {
        fs.rmSync(destination, { force: true });
        throw new Error("Download kosong.");
    }

    console.log("\nDownload berhasil!");
}

// =====================================
// ROOTFS URL
// =====================================

async function findRootfsURL(config) {
    if (ROOTFS_CACHE.has(config.id)) {
        return ROOTFS_CACHE.get(config.id);
    }

    const base =
        `${IMAGE_SERVER}/images/${config.distro}/${config.version}/${ARCH}/default/`;

    console.log("\nMengambil daftar build rootfs...");
    console.log("Distro:", config.name);
    console.log("Arsitektur:", ARCH);

    const response = await request(base);

    let html = "";

    for await (const chunk of response) {
        html += chunk.toString();
    }

    const versions = [
        ...html.matchAll(/href=["']?(20\d{6}_[^"'/?]+)\/?["']?/g)
    ]
        .map(match => match[1])
        .filter((value, index, array) => array.indexOf(value) === index)
        .sort()
        .reverse();

    if (!versions.length) {
        throw new Error("Tidak ditemukan direktori build untuk " + config.name);
    }

    const selectedVersion = versions[0];
    const url = `${base}${selectedVersion}/rootfs.tar.xz`;

    ROOTFS_CACHE.set(config.id, url);

    console.log("\nBuild terbaru ditemukan:");
    console.log(selectedVersion);
    console.log("\nURL ROOTFS:");
    console.log(url);

    return url;
}

async function getRootfsURL(config) {
    console.log("\nMenyiapkan rootfs:", config.name);
    console.log("Arsitektur:", ARCH);

    return await findRootfsURL(config);
}

// =====================================
// PROOT MULTI ARCHITECTURE
// =====================================

const PROOT_URLS = {
    amd64:
        "https://github.com/upleung/proot-releases/releases/latest/download/proot-v5.5.0-x86_64-static",

    arm64:
        "https://github.com/upleung/proot-releases/releases/latest/download/proot-v5.5.0-aarch64-static",

    armhf:
        "https://github.com/upleung/proot-releases/releases/latest/download/proot-v5.5.0-arm-static"
};

// =====================================
// VALIDASI PROOT
// =====================================

function validateProot(binary) {
    if (!fs.existsSync(binary)) {
        return false;
    }

    try {
        const result = spawnSync(binary, ["--version"], {
            encoding: "utf8",
            timeout: 15000,
            stdio: ["ignore", "pipe", "pipe"]
        });

        return !result.error && result.status === 0;
    } catch {
        return false;
    }
}

// =====================================
// INSTALL PROOT
// =====================================

async function installProot() {
    console.log("\n================================");
    console.log("PROOT INSTALLER");
    console.log("================================");
    console.log("Arsitektur:", ARCH);

    const url = PROOT_URLS[ARCH];

    if (!url) {
        throw new Error(
            "Binary PRoot tidak tersedia untuk arsitektur " +
            ARCH +
            ". Arsitektur yang didukung: AMD64, ARM64, ARMHF."
        );
    }

    if (fs.existsSync(PROOT)) {
        console.log("\nMemeriksa PRoot lokal...");

        if (validateProot(PROOT)) {
            console.log("PRoot lokal cocok dan bisa dijalankan!");
            return PROOT;
        }

        console.log("PRoot lokal tidak cocok atau rusak.");
        console.log("Mengunduh binary yang sesuai...");

        fs.rmSync(PROOT, { force: true });
    }

    const systemProot = spawnSync(
        "sh",
        ["-c", "command -v proot"],
        { encoding: "utf8" }
    );

    if (systemProot.status === 0) {
        const systemPath = systemProot.stdout.trim();

        if (systemPath && validateProot(systemPath)) {
            console.log("Menggunakan PRoot sistem yang kompatibel.");
            return systemPath;
        }
    }

    console.log("\nMengunduh PRoot khusus:", ARCH);
    console.log("Sumber:", url);

    await download(url, PROOT);
    fs.chmodSync(PROOT, 0o755);

    console.log("\nMemeriksa binary PRoot...");

    if (!validateProot(PROOT)) {
        fs.rmSync(PROOT, { force: true });

        throw new Error(
            "PRoot gagal dijalankan. Binary mungkin tidak cocok dengan arsitektur server."
        );
    }

    console.log("\nPRoot berhasil dipasang!");
    console.log("Arsitektur PRoot:", ARCH);

    return PROOT;
}

// =====================================
// KONFIGURASI DNS
// =====================================

function configureDNS(rootfs) {
    const etc = path.join(rootfs, "etc");

    fs.mkdirSync(etc, { recursive: true });

    const resolv = path.join(etc, "resolv.conf");

    fs.rmSync(resolv, { force: true });

    fs.writeFileSync(
        resolv,
        "nameserver 1.1.1.1\nnameserver 8.8.8.8\n"
    );
}

// =====================================
// HOSTNAME
// =====================================

function configureHostname(rootfs, config) {
    const etc = path.join(rootfs, "etc");

    fs.mkdirSync(etc, { recursive: true });

    fs.writeFileSync(
        path.join(etc, "hostname"),
        config.id + "\n"
    );

    fs.writeFileSync(
        path.join(etc, "hosts"),
        `127.0.0.1 localhost
127.0.1.1 ${config.id}

::1 localhost ip6-localhost ip6-loopback
`
    );
}

// =====================================
// GROUPS
// =====================================

function configureGroups(rootfs) {
    const groupFile = path.join(rootfs, "etc", "group");

    fs.mkdirSync(path.dirname(groupFile), {
        recursive: true
    });

    if (!fs.existsSync(groupFile)) {
        fs.writeFileSync(groupFile, "");
    }

    let content = fs.readFileSync(groupFile, "utf8");

    const existingGids = new Set(
        content
            .split("\n")
            .map(line => line.trim().split(":")[2])
            .filter(Boolean)
    );

    const gids = new Set();

    function addGid(value) {
        const gid = Number(value);

        if (Number.isInteger(gid) && gid >= 0) {
            gids.add(gid);
        }
    }

    try {
        if (typeof process.getgroups === "function") {
            process.getgroups().forEach(addGid);
        }

        if (typeof process.getgid === "function") {
            addGid(process.getgid());
        }

        if (typeof process.getegid === "function") {
            addGid(process.getegid());
        }
    } catch {}

    try {
        const status = fs.readFileSync("/proc/self/status", "utf8");

        const gidLine = status.match(/^Gid:\s+(.+)$/m);
        const groupsLine = status.match(/^Groups:\s*(.*)$/m);

        if (gidLine) {
            gidLine[1].trim().split(/\s+/).forEach(addGid);
        }

        if (groupsLine && groupsLine[1].trim()) {
            groupsLine[1].trim().split(/\s+/).forEach(addGid);
        }
    } catch {}

    for (const gid of gids) {
        const id = String(gid);

        if (!existingGids.has(id)) {
            content += `hostgroup${id}:x:${id}:\n`;
            existingGids.add(id);
        }
    }

    fs.writeFileSync(groupFile, content);
}

// =====================================
// BASH TERMINAL
// FIX PROMPT PERMANEN
// =====================================

function configureBash(rootfs, config) {
    const root = path.join(rootfs, "root");

    fs.mkdirSync(root, { recursive: true });

    const bashrc = path.join(root, ".bashrc");
    const terminalRC = path.join(root, ".rootfs-terminal.bashrc");

    const markerStart = "# ROOTFS_INSTALLER_PROMPT_START";
    const markerEnd = "# ROOTFS_INSTALLER_PROMPT_END";

    const promptConfig = `
${markerStart}
case "$-" in
    *i*) ;;
    *) return ;;
esac

unset PROMPT_COMMAND
PS1='root@${config.id}:~#\\nroot@${config.id}:~# '
PS2='> '
${markerEnd}
`;

    // Baca .bashrc bawaan distro.
    let bashrcContent = "";

    if (fs.existsSync(bashrc)) {
        bashrcContent = fs.readFileSync(bashrc, "utf8");
    }

    // Hapus konfigurasi prompt installer yang lama.
    const escapedStart = markerStart.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const escapedEnd = markerEnd.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

    const managedBlock = new RegExp(
        `${escapedStart}[\\s\\S]*?${escapedEnd}`,
        "g"
    );

    bashrcContent = bashrcContent.replace(managedBlock, "").trimEnd();

    // Pasang konfigurasi prompt di bagian paling akhir .bashrc.
    bashrcContent += "\n\n" + promptConfig.trim() + "\n";

    fs.writeFileSync(bashrc, bashrcContent);
    fs.chmodSync(bashrc, 0o644);

    // RC khusus untuk terminal yang dijalankan installer.
    const terminalContent = `
export HOME=/root
export USER=root
export LOGNAME=root

export TERM=xterm-256color
export CLICOLOR=1
export FORCE_COLOR=1

shopt -s checkwinsize
shopt -s cmdhist
shopt -s histappend

# Muat konfigurasi bash utama.
if [ -f /root/.bashrc ]; then
    source /root/.bashrc
fi

# Pastikan prompt installer tetap digunakan.
unset PROMPT_COMMAND
PS1='root@${config.id}:~#\\nroot@${config.id}:~# '
PS2='> '
`;

    fs.writeFileSync(terminalRC, terminalContent);
    fs.chmodSync(terminalRC, 0o644);
}

// =====================================
// APT CONFIGURATION
// =====================================

function configureAPT(rootfs) {
    const aptConfig = path.join(
        rootfs,
        "etc",
        "apt",
        "apt.conf.d"
    );

    fs.mkdirSync(aptConfig, { recursive: true });

    const content = `
Dpkg::Use-Pty "false";
APT::Color "1";
Dpkg::Progress-Fancy "0";
APT::Get::Assume-Yes "false";
`;

    fs.writeFileSync(
        path.join(aptConfig, "99-rootfs-terminal"),
        content
    );
}

// =====================================
// REPOSITORIES
// =====================================

function configureRepositories(config, rootfs) {
    const apt = path.join(rootfs, "etc/apt");

    fs.mkdirSync(apt, { recursive: true });

    let sources = "";

    if (config.distro === "debian") {
        if (config.version === "buster") {
            sources = [
                "deb http://archive.debian.org/debian buster main contrib non-free",
                "deb http://archive.debian.org/debian-security buster/updates main contrib non-free"
            ].join("\n");
        } else {
            const components =
                config.version === "bullseye"
                    ? "main contrib non-free"
                    : "main contrib non-free non-free-firmware";

            sources = [
                `deb http://deb.debian.org/debian ${config.version} ${components}`,
                `deb http://deb.debian.org/debian ${config.version}-updates ${components}`,
                `deb http://security.debian.org/debian-security ${config.version}-security ${components}`
            ].join("\n");
        }
    }

    if (config.distro === "ubuntu") {
        const mirror =
            ARCH === "arm64" || ARCH === "armhf"
                ? "http://ports.ubuntu.com/ubuntu-ports"
                : "http://archive.ubuntu.com/ubuntu";

        if (config.version === "focal") {
            sources = [
                "deb http://old-releases.ubuntu.com/ubuntu/ focal main restricted universe multiverse",
                "deb http://old-releases.ubuntu.com/ubuntu/ focal-updates main restricted universe multiverse",
                "deb http://old-releases.ubuntu.com/ubuntu/ focal-security main restricted universe multiverse"
            ].join("\n");
        } else {
            sources = [
                `deb ${mirror} ${config.version} main restricted universe multiverse`,
                `deb ${mirror} ${config.version}-updates main restricted universe multiverse`,
                `deb ${mirror} ${config.version}-backports main restricted universe multiverse`,
                `deb ${mirror} ${config.version}-security main restricted universe multiverse`
            ].join("\n");
        }
    }

    fs.writeFileSync(
        path.join(apt, "sources.list"),
        sources + "\n"
    );
}

// =====================================
// STATUS INSTALL
// =====================================

function isInstalled(config) {
    const rootfs = path.join(BASE, config.id);

    return (
        fs.existsSync(path.join(rootfs, "bin")) &&
        fs.existsSync(path.join(rootfs, "etc"))
    );
}

function getInstalledDistros() {
    return ALL_DISTROS.filter(isInstalled);
}

function getExistingContainer() {
    const installed = getInstalledDistros();

    return installed.length > 0
        ? installed[0]
        : null;
}

function getLastDistro() {
    const installed = getInstalledDistros();

    if (!installed.length) {
        return null;
    }

    try {
        const lastId = fs.readFileSync(
            LAST_DISTRO_FILE,
            "utf8"
        ).trim();

        const last = installed.find(
            distro => distro.id === lastId
        );

        if (last) return last;
    } catch {}

    return installed[0];
}

function saveLastDistro(config) {
    fs.writeFileSync(
        LAST_DISTRO_FILE,
        config.id
    );
}

// =====================================
// INSTALL ROOTFS
// =====================================

async function installRootfs(config) {
    const rootfs = path.join(BASE, config.id);

    const archive = path.join(
        BASE,
        config.id + ".tar.xz"
    );

    if (isInstalled(config)) {
        console.log(
            config.name +
            " sudah terinstall. Membuka instalasi yang ada."
        );

        return rootfs;
    }

    const existing = getExistingContainer();

    if (existing) {
        throw new Error(
            `Container ${existing.name} sudah terpasang. ` +
            "Gunakan Reset All untuk mengganti distro."
        );
    }

    if (fs.existsSync(rootfs)) {
        fs.rmSync(rootfs, {
            recursive: true,
            force: true
        });
    }

    fs.mkdirSync(rootfs, {
        recursive: true
    });

    const url = await getRootfsURL(config);

    await download(url, archive);

    console.log("\nMengekstrak", config.name, "...");

    const result = spawnSync("tar", [
        "-xJf",
        archive,
        "-C",
        rootfs
    ], {
        stdio: "inherit"
    });

    if (result.status !== 0) {
        fs.rmSync(archive, { force: true });

        fs.rmSync(rootfs, {
            recursive: true,
            force: true
        });

        throw new Error("Ekstraksi rootfs gagal.");
    }

    fs.rmSync(archive, {
        force: true
    });

    if (!isInstalled(config)) {
        fs.rmSync(rootfs, {
            recursive: true,
            force: true
        });

        throw new Error("Rootfs tidak lengkap setelah ekstraksi.");
    }

    console.log("\nRootfs berhasil dipasang!");

    return rootfs;
}

// =====================================
// START LINUX
// =====================================

async function startLinux(config) {
    const rootfs = await installRootfs(config);

    configureDNS(rootfs);
    configureHostname(rootfs, config);
    configureGroups(rootfs);
    configureBash(rootfs, config);
    configureRepositories(config, rootfs);
    configureAPT(rootfs);

    const prootPath = await installProot();

    saveLastDistro(config);

    clearTerminal();

    console.log("================================");
    console.log("MEMULAI " + config.name);
    console.log("================================");
    console.log("Host architecture:", ARCH);
    console.log("PRoot:", prootPath);

    const child = spawn(prootPath, [
        "-0",
        "-r", rootfs,
        "-w", "/root",
        "-b", "/dev",
        "-b", "/proc",
        "-b", "/sys",
        "-b", "/tmp",
        "/usr/bin/env",
        "-i",
        "HOME=/root",
        "USER=root",
        "LOGNAME=root",
        "TERM=xterm-256color",
        "CLICOLOR=1",
        "FORCE_COLOR=1",
        "DEBIAN_FRONTEND=readline",
        "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        "/bin/bash",
        "--noprofile",
        "--rcfile",
        "/root/.rootfs-terminal.bashrc",
        "-i"
    ], {
        stdio: "inherit",
        env: process.env
    });

    await new Promise((resolve, reject) => {
        child.once("error", error => {
            reject(
                new Error("Gagal menjalankan PRoot: " + error.message)
            );
        });

        child.once("exit", (code, signal) => {
            clearTerminal();

            console.log("Linux berhenti.");
            console.log("Exit code:", code);

            if (signal) {
                console.log("Signal:", signal);
            }

            resolve();
        });
    });
}

// =====================================
// LOGIN LANGSUNG
// =====================================

async function loginDirect() {
    const config = getLastDistro();

    clearTerminal();

    if (!config) {
        console.log("Belum ada container yang terinstall.");
        await ask("Tekan Enter untuk kembali...");
        return;
    }

    try {
        await startLinux(config);
    } catch (error) {
        clearTerminal();

        console.error(
            "GAGAL MASUK:",
            error.message
        );

        await ask("Tekan Enter untuk kembali...");
    }
}

// =====================================
// RESET ALL
// =====================================

async function resetAll() {
    clearTerminal();

    console.log("========== RESET ALL ==========");
    console.log("Semua isi folder akan dihapus kecuali index.js!");

    const answer = await ask("Ketik RESET untuk melanjutkan:");

    fakeEnter();

    if (answer !== "RESET") {
        console.log("Reset dibatalkan.");
        await ask("Tekan Enter untuk kembali...");
        return;
    }

    const protectedFile = path.resolve(__filename);

    for (const item of fs.readdirSync(BASE)) {
        const target = path.resolve(BASE, item);

        if (target === protectedFile) continue;

        try {
            fs.rmSync(target, {
                recursive: true,
                force: true
            });

            console.log("Dihapus:", item);
        } catch (error) {
            console.log(
                "Gagal:",
                item,
                error.message
            );
        }
    }

    ROOTFS_CACHE.clear();

    console.log("\nReset selesai! index.js aman.");

    await ask("Tekan Enter untuk kembali...");
}

// =====================================
// VERSION MENU
// =====================================

async function versionMenu(type) {
    clearTerminal();

    const versions = DISTROS[type];

    while (true) {
        clearTerminal();

        const existing = getExistingContainer();

        console.log("========== " + type.toUpperCase() + " ==========");
        console.log("Arsitektur:", ARCH);
        console.log("");

        versions.forEach((distro, index) => {
            let status = "";

            if (isInstalled(distro)) {
                status = " [SUDAH TERINSTALL]";
            } else if (existing) {
                status = " [DIKUNCI]";
            }

            console.log(
                `${index + 1}. ${distro.name}${status}`
            );
        });

        console.log("");
        console.log("0. Kembali");

        const choice = await ask("Pilih versi:");

        fakeEnter();

        if (choice === "0") return;

        const config = versions[Number(choice) - 1];

        if (!config) {
            console.log("Pilihan tidak valid.");
            await ask("Tekan Enter untuk lanjut...");
            continue;
        }

        if (isInstalled(config)) {
            console.log(
                "\n" + config.name + " sudah terinstall!"
            );

            console.log(
                "Membuka terminal yang sudah terpasang..."
            );

            try {
                await startLinux(config);
            } catch (error) {
                console.error("ERROR:", error.message);
                await ask("Tekan Enter untuk kembali...");
            }

            continue;
        }

        const current = getExistingContainer();

        if (current) {
            console.log("\nINSTALLASI DITOLAK!");

            console.log(
                "Container yang sudah terpasang:",
                current.name
            );

            console.log(
                "Kamu hanya boleh menggunakan satu container."
            );

            console.log(
                "Gunakan Reset All jika ingin mengganti distro."
            );

            await ask("Tekan Enter untuk kembali...");
            continue;
        }

        try {
            await startLinux(config);
        } catch (error) {
            clearTerminal();

            console.error(
                "\nINSTALLASI GAGAL:",
                error.message
            );

            await ask("Tekan Enter untuk kembali...");
        }
    }
}

// =====================================
// MAIN MENU
// =====================================

async function main() {
    while (true) {
        clearTerminal();

        const current = getLastDistro();

        console.log("================================");
        console.log("       LINUX ROOTFS INSTALLER");
        console.log("================================");

        console.log(
            "Arsitektur terdeteksi:",
            ARCH
        );

        console.log("");
        console.log("1. Debian");
        console.log("2. Ubuntu");

        if (current) {
            console.log(
                `3. Masuk Terminal (${current.name})`
            );
        } else {
            console.log(
                "3. Masuk Terminal [BELUM ADA CONTAINER]"
            );
        }

        console.log("4. Reset All");
        console.log("0. Keluar");
        console.log("================================");

        const choice = await ask("Pilih:");

        fakeEnter();

        if (choice === "0") {
            clearTerminal();
            console.log("Keluar.");
            return;
        }

        if (choice === "1") {
            await versionMenu("debian");
        } else if (choice === "2") {
            await versionMenu("ubuntu");
        } else if (choice === "3") {
            await loginDirect();
        } else if (choice === "4") {
            await resetAll();
        } else {
            console.log("Pilihan tidak valid.");
            await ask("Tekan Enter untuk lanjut...");
        }
    }
}

// =====================================
// RUN
// =====================================

main().catch(error => {
    clearTerminal();

    console.error(
        "\nERROR:",
        error.message
    );
});
