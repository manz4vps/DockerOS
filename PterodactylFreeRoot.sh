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
    console.log("process.arch:", process.arch);
    console.log("HOSTTYPE:", process.env.HOSTTYPE || "unknown");
    console.log("ARCH:", process.env.ARCH || "unknown");
    process.exit(1);
}

// =====================================
// DAFTAR DISTRO
// VERSI TERBARU NOMOR 1
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
            output: process.stdout,
            terminal: true
        });

        // Input ditampilkan di baris berikutnya.
        const prompt = question.endsWith("\n")
            ? question
            : question + "\n";

        rl.question(prompt, answer => {
            rl.close();
            resolve(answer.trim());
        });
    });
}

function clearTerminal() {
    process.stdout.write("\x1Bc");
}

function fakeEnter() {
    process.stdout.write("\r\n\r\n");
}

// =====================================
// HTTP REQUEST
// =====================================

function request(url, redirects = 8, method = "GET") {
    return new Promise((resolve, reject) => {
        const req = https.request(url, {
            method,
            headers: {
                "User-Agent": "Linux-Rootfs-Installer"
            }
        }, res => {
            if ([301, 302, 303, 307, 308].includes(res.statusCode)) {
                const location = res.headers.location;
                res.resume();

                if (!redirects) {
                    return reject(new Error("Terlalu banyak redirect"));
                }

                if (!location) {
                    return reject(new Error("Redirect tidak memiliki alamat tujuan"));
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

                return reject(
                    new Error("HTTP " + res.statusCode + " saat mengakses " + url)
                );
            }

            resolve(res);
        });

        req.on("error", reject);
        req.end();
    });
}

async function checkURL(url) {
    try {
        const response = await request(url, 8, "HEAD");
        response.resume();
        return true;
    } catch {
        return false;
    }
}

// =====================================
// DOWNLOAD
// =====================================

async function download(url, destination) {
    console.log("\nDownload:", url);

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

    if (!fs.existsSync(destination) || fs.statSync(destination).size === 0) {
        fs.rmSync(destination, { force: true });
        throw new Error("File download kosong.");
    }
}

// =====================================
// CEK ROOTFS TERSEDIA
// =====================================

async function findRootfsURL(config) {
    if (ROOTFS_CACHE.has(config.id)) {
        return ROOTFS_CACHE.get(config.id);
    }

    const base =
        `${IMAGE_SERVER}/images/${config.distro}/${config.version}/${ARCH}/default/`;

    let response;

    try {
        response = await request(base);
    } catch {
        ROOTFS_CACHE.set(config.id, null);
        return null;
    }

    let html = "";

    for await (const chunk of response) {
        html += chunk;
    }

    const versions = [
        ...html.matchAll(/href=["'](20\d{6}_[^"'/]+)\/["']/g)
    ]
        .map(match => match[1])
        .sort()
        .reverse();

    if (!versions.length) {
        ROOTFS_CACHE.set(config.id, null);
        return null;
    }

    for (const version of versions) {
        const url = `${base}${version}/rootfs.tar.xz`;

        if (await checkURL(url)) {
            ROOTFS_CACHE.set(config.id, url);
            return url;
        }
    }

    ROOTFS_CACHE.set(config.id, null);
    return null;
}

async function getRootfsURL(config) {
    console.log("\nMemeriksa rootfs:", config.name);
    console.log("Arsitektur:", ARCH);

    const url = await findRootfsURL(config);

    if (!url) {
        throw new Error(
            `${config.name} tidak tersedia untuk arsitektur ${ARCH}.`
        );
    }

    console.log("Rootfs ditemukan:", url);

    return url;
}

async function getAvailableDistros(type) {
    const available = [];

    console.log("\nMemeriksa ketersediaan rootfs...");
    console.log("Arsitektur:", ARCH);

    for (const config of DISTROS[type]) {
        process.stdout.write(`Memeriksa ${config.name}... `);

        const url = await findRootfsURL(config);

        if (url) {
            console.log("TERSEDIA");
            available.push(config);
        } else {
            console.log("TIDAK TERSEDIA");
        }
    }

    return available;
}

// =====================================
// PROOT
// =====================================

function commandExists(cmd) {
    return spawnSync("sh", ["-c", `command -v ${cmd}`], {
        stdio: "ignore"
    }).status === 0;
}

async function installProot() {
    if (commandExists("proot")) return "proot";

    if (fs.existsSync(PROOT)) return PROOT;

    console.log("\nMengunduh PRoot...");

    await download(
        "https://proot.gitlab.io/proot/bin/proot",
        PROOT
    );

    fs.chmodSync(PROOT, 0o755);

    return PROOT;
}

// =====================================
// KONFIGURASI LINUX
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

function configureHostname(rootfs, config) {
    const etc = path.join(rootfs, "etc");

    fs.mkdirSync(etc, { recursive: true });

    fs.writeFileSync(
        path.join(etc, "hostname"),
        config.id + "\n"
    );

    fs.writeFileSync(
        path.join(etc, "hosts"),
        `127.0.0.1 localhost\n127.0.1.1 ${config.id}\n\n::1 localhost ip6-localhost ip6-loopback\n`
    );
}

function configureGroups(rootfs) {
    const groupFile = path.join(rootfs, "etc", "group");

    fs.mkdirSync(path.dirname(groupFile), { recursive: true });

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
// =====================================

function configureBash(rootfs, config) {
    const root = path.join(rootfs, "root");

    fs.mkdirSync(root, { recursive: true });

    const terminalRC = path.join(root, ".rootfs-terminal.bashrc");

    const content = `
export HOME=/root
export USER=root
export LOGNAME=root

export TERM=xterm-256color
export CLICOLOR=1
export FORCE_COLOR=1

export PS0=''

# Prompt di baris pertama, input di baris kedua.
export PS1='root@${config.id}:~# \\n'

export PS2='> '

unset PROMPT_COMMAND

shopt -s checkwinsize
shopt -s cmdhist
shopt -s histappend
`;

    fs.writeFileSync(terminalRC, content);
    fs.chmodSync(terminalRC, 0o644);
}

// =====================================
// APT TERMINAL CONFIGURATION
// =====================================

function configureAPT(rootfs) {
    const aptConfig = path.join(rootfs, "etc", "apt", "apt.conf.d");

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

    return installed.length > 0 ? installed[0] : null;
}

function getLastDistro() {
    const installed = getInstalledDistros();

    if (!installed.length) {
        return null;
    }

    try {
        const lastId = fs.readFileSync(LAST_DISTRO_FILE, "utf8").trim();

        const last = installed.find(distro => distro.id === lastId);

        if (last) return last;
    } catch {}

    return installed[0];
}

function saveLastDistro(config) {
    fs.writeFileSync(LAST_DISTRO_FILE, config.id);
}

// =====================================
// INSTALL ROOTFS
// =====================================

async function installRootfs(config) {
    const rootfs = path.join(BASE, config.id);
    const archive = path.join(BASE, config.id + ".tar.xz");

    if (isInstalled(config)) {
        console.log(config.name + " sudah terinstall. Membuka instalasi yang ada.");
        return rootfs;
    }

    const existing = getExistingContainer();

    if (existing) {
        throw new Error(
            `Container ${existing.name} sudah terpasang. Tidak boleh memasang distro lain.`
        );
    }

    if (fs.existsSync(rootfs)) {
        fs.rmSync(rootfs, {
            recursive: true,
            force: true
        });
    }

    fs.mkdirSync(rootfs, { recursive: true });

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
        fs.rmSync(rootfs, { recursive: true, force: true });
        throw new Error("Ekstraksi rootfs gagal.");
    }

    fs.rmSync(archive, { force: true });

    if (!isInstalled(config)) {
        fs.rmSync(rootfs, {
            recursive: true,
            force: true
        });

        throw new Error("Rootfs tidak lengkap setelah ekstraksi.");
    }

    console.log("Rootfs berhasil dipasang!");

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
        child.once("error", reject);

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
        await ask("\nTekan Enter untuk kembali...");
        return;
    }

    try {
        await startLinux(config);
    } catch (error) {
        clearTerminal();
        console.error("GAGAL MASUK:", error.message);
        await ask("\nTekan Enter untuk kembali...");
    }
}

// =====================================
// RESET ALL
// =====================================

async function resetAll() {
    clearTerminal();

    console.log("========== RESET ALL ==========");
    console.log("Semua isi folder akan dihapus kecuali index.js!");

    const answer = await ask("\nKetik RESET untuk melanjutkan: ");
    fakeEnter();

    if (answer !== "RESET") {
        console.log("Reset dibatalkan.");
        await ask("\nTekan Enter untuk kembali...");
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
            console.log("Gagal:", item, error.message);
        }
    }

    ROOTFS_CACHE.clear();

    console.log("\nReset selesai! index.js aman.");
    await ask("\nTekan Enter untuk kembali...");
}

// =====================================
// VERSION MENU
// =====================================

async function versionMenu(type) {
    clearTerminal();

    console.log("========== CEK DISTRO ==========");

    let versions;

    try {
        versions = await getAvailableDistros(type);
    } catch (error) {
        console.log("\nGagal memeriksa daftar distro:", error.message);
        await ask("\nTekan Enter untuk kembali...");
        return;
    }

    while (true) {
        clearTerminal();

        const existing = getExistingContainer();

        console.log("========== " + type.toUpperCase() + " ==========");
        console.log("Arsitektur:", ARCH);
        console.log("");

        if (!versions.length) {
            console.log("Tidak ada rootfs yang tersedia untuk arsitektur ini.");
            console.log("Silakan coba lagi nanti.");
            await ask("\nTekan Enter untuk kembali...");
            return;
        }

        versions.forEach((distro, index) => {
            let status = "";

            if (isInstalled(distro)) {
                status = " [SUDAH TERINSTALL]";
            } else if (existing) {
                status = " [DIKUNCI]";
            }

            console.log(`${index + 1}. ${distro.name}${status}`);
        });

        console.log("0. Kembali");

        const choice = await ask("Pilih versi: ");
        fakeEnter();

        if (choice === "0") return;

        const config = versions[Number(choice) - 1];

        if (!config) {
            console.log("Pilihan tidak valid.");
            await ask("\nTekan Enter untuk lanjut...");
            continue;
        }

        if (isInstalled(config)) {
            console.log("\n" + config.name + " sudah terinstall!");
            console.log("Membuka terminal yang sudah terpasang...");

            try {
                await startLinux(config);
            } catch (error) {
                console.error("ERROR:", error.message);
                await ask("\nTekan Enter untuk kembali...");
            }

            continue;
        }

        const current = getExistingContainer();

        if (current) {
            console.log("\nINSTALLASI DITOLAK!");
            console.log("Container yang sudah terpasang:", current.name);
            console.log("Kamu hanya boleh menggunakan satu container.");
            console.log("Gunakan Reset All jika ingin mengganti distro.");

            await ask("\nTekan Enter untuk kembali...");
            continue;
        }

        try {
            await startLinux(config);
        } catch (error) {
            clearTerminal();
            console.error("ERROR:", error.message);
            await ask("\nTekan Enter untuk kembali...");
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

        console.log("Arsitektur terdeteksi:", ARCH);
        console.log("");

        console.log("1. Debian");
        console.log("2. Ubuntu");

        if (current) {
            console.log(`3. Masuk Terminal (${current.name})`);
        } else {
            console.log("3. Masuk Terminal [BELUM ADA CONTAINER]");
        }

        console.log("4. Reset All");
        console.log("0. Keluar");
        console.log("================================");

        const choice = await ask("Pilih: ");
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
            await ask("\nTekan Enter untuk lanjut...");
        }
    }
}

main().catch(error => {
    clearTerminal();
    console.error("\nERROR:", error.message);
});