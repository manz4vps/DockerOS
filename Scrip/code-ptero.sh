const fs = require("fs");
const os = require("os");
const path = require("path");
const https = require("https");
const { spawn, execFileSync } = require("child_process");
const readline = require("readline");

const BASE = "/home/container";
const ROOT = path.join(BASE, "ubuntu");
const BIN_DIR = path.join(BASE, "bin");
const PROOT = path.join(BIN_DIR, "proot");
const WORKSPACE = path.join(BASE, "workspace");
const CONFIG_FILE = path.join(BASE, "manager.json");

const CODE_VERSION = "4.96.4";
const DEFAULT_PORT = "4178";

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
});

const UBUNTU = {
    "20.04": {
        name: "Ubuntu 20.04 LTS",
        url: "https://partner-images.canonical.com/core/focal/current/ubuntu-focal-core-cloudimg-amd64-root.tar.gz"
    },
    "22.04": {
        name: "Ubuntu 22.04 LTS",
        url: "https://partner-images.canonical.com/core/jammy/20230510/ubuntu-jammy-core-cloudimg-amd64-root.tar.gz"
    },
    "24.04": {
        name: "Ubuntu 24.04 LTS",
        url: "https://partner-images.canonical.com/oci/noble/current/ubuntu-noble-oci-amd64-root.tar.gz"
    }
};

function log(message) {
    console.log(`[MANAGER] ${message}`);
}

// INPUT: setiap jawaban otomatis pindah baris
function ask(question) {
    return new Promise(resolve => {
        console.log(question);

        rl.question("", answer => {
            resolve(answer.trim());
        });
    });
}

function detectArchitecture() {
    let arch = os.arch();

    try {
        arch = execFileSync("uname", ["-m"], {
            encoding: "utf8"
        }).trim();
    } catch {}

    const map = {
        "x86_64": "amd64",
        "x64": "amd64",
        "aarch64": "arm64",
        "arm64": "arm64",
        "armv7l": "armhf",
        "arm": "arm",
        "i686": "i386",
        "i386": "i386"
    };

    return map[arch] || arch;
}

function ensureDirectories() {
    fs.mkdirSync(BASE, { recursive: true });
    fs.mkdirSync(BIN_DIR, { recursive: true });
    fs.mkdirSync(WORKSPACE, { recursive: true });
}

function loadConfig() {
    try {
        return JSON.parse(
            fs.readFileSync(CONFIG_FILE, "utf8")
        );
    } catch {
        return null;
    }
}

function saveConfig(config) {
    const temp = CONFIG_FILE + ".tmp";

    fs.writeFileSync(
        temp,
        JSON.stringify(config, null, 2),
        { mode: 0o600 }
    );

    fs.renameSync(temp, CONFIG_FILE);

    try {
        fs.chmodSync(CONFIG_FILE, 0o600);
    } catch {}
}

function download(url, destination) {
    return new Promise((resolve, reject) => {
        log(`Downloading: ${url}`);

        const file = fs.createWriteStream(destination);
        let finished = false;

        function fail(error) {
            if (finished) return;
            finished = true;

            file.destroy();

            try {
                fs.unlinkSync(destination);
            } catch {}

            reject(error);
        }

        function request(target, redirects = 0) {
            if (redirects > 10) {
                fail(new Error("Terlalu banyak redirect."));
                return;
            }

            https.get(target, response => {
                if (
                    response.statusCode >= 300 &&
                    response.statusCode < 400 &&
                    response.headers.location
                ) {
                    response.resume();

                    request(
                        new URL(
                            response.headers.location,
                            target
                        ).href,
                        redirects + 1
                    );

                    return;
                }

                if (response.statusCode !== 200) {
                    response.resume();

                    fail(new Error(
                        `HTTP Error: ${response.statusCode}`
                    ));

                    return;
                }

                response.pipe(file);

                file.on("finish", () => {
                    file.close(() => {
                        if (finished) return;
                        finished = true;
                        resolve();
                    });
                });

            }).on("error", fail);
        }

        request(url);
    });
}

function run(command, args, options = {}) {
    return new Promise((resolve, reject) => {
        const child = spawn(command, args, {
            stdio: "inherit",
            ...options
        });

        child.on("error", reject);

        child.on("close", code => {
            if (code === 0) {
                resolve();
            } else {
                reject(new Error(
                    `${command} berhenti dengan kode ${code}`
                ));
            }
        });
    });
}

function prootArgs(command) {
    const args = [
        "-0",
        "-r", ROOT,
        "-w", "/root",
        "-b", "/dev",
        "-b", "/proc",
        "-b", "/sys",
        "-b", `${WORKSPACE}:/workspace`
    ];

    if (fs.existsSync("/etc/resolv.conf")) {
        args.push("-b", "/etc/resolv.conf");
    }

    args.push(...command);

    return args;
}

async function guest(command) {
    await run(
        PROOT,
        prootArgs(command),
        {
            env: {
                ...process.env,
                HOME: "/root",
                USER: "root",
                LOGNAME: "root",
                DEBIAN_FRONTEND: "noninteractive"
            }
        }
    );
}

async function chooseUbuntu(current = "22.04") {
    console.log("");
    console.log("========== PILIH UBUNTU ==========");
    console.log("[1] Ubuntu 20.04 LTS");
    console.log("[2] Ubuntu 22.04 LTS");
    console.log("[3] Ubuntu 24.04 LTS");
    console.log("==================================");

    const choices = {
        "1": "20.04",
        "2": "22.04",
        "3": "24.04"
    };

    while (true) {
        const answer = await ask(
            `Pilih versi Ubuntu [default ${current}]: `
        );

        if (!answer) return current;
        if (choices[answer]) return choices[answer];
        if (UBUNTU[answer]) return answer;

        console.log("Pilihan tidak valid.");
    }
}

async function askPassword(current = "") {
    while (true) {
        const password = await ask(
            current
                ? "Password baru (kosong = tetap):"
                : "Masukkan password code-server:"
        );

        if (!password && current) {
            return current;
        }

        if (/[\r\n]/.test(password)) {
            console.log("Password tidak valid.");
            continue;
        }

        return password;
    }
}

async function askPort(current = DEFAULT_PORT) {
    while (true) {
        const answer = await ask(
            `Masukkan port [default ${current}]: `
        );

        const port = answer || current;
        const number = Number(port);

        if (
            Number.isInteger(number) &&
            number >= 1024 &&
            number <= 65535
        ) {
            return String(number);
        }

        console.log("Port harus angka 1024-65535.");
    }
}

async function firstSetup() {
    console.log("");
    console.log("==================================");
    console.log("       UBUNTU SERVER MANAGER");
    console.log("==================================");

    const version = await chooseUbuntu("22.04");
    const password = await askPassword();
    const port = await askPort();

    const config = {
        ubuntu: version,
        password,
        port
    };

    saveConfig(config);

    console.log("");
    console.log("Konfigurasi berhasil disimpan!");

    return config;
}

async function installProot() {
    if (fs.existsSync(PROOT)) {
        return;
    }

    log("Mengunduh PRoot...");

    await download(
        "https://proot.gitlab.io/proot/bin/proot",
        PROOT
    );

    fs.chmodSync(PROOT, 0o755);

    log("PRoot berhasil dipasang.");
}

async function installUbuntu(config) {
    const marker = path.join(ROOT, ".rootfs-ready");

    if (fs.existsSync(marker)) {
        log("Ubuntu sudah terpasang.");
        return;
    }

    if (fs.existsSync(ROOT)) {
        fs.rmSync(ROOT, {
            recursive: true,
            force: true
        });
    }

    fs.mkdirSync(ROOT, { recursive: true });

    const archive = path.join(
        BASE,
        "ubuntu-rootfs.tar.gz"
    );

    log(`Mengunduh ${UBUNTU[config.ubuntu].name}...`);

    await download(
        UBUNTU[config.ubuntu].url,
        archive
    );

    log("Mengekstrak Ubuntu...");

    await run("tar", [
        "-xzf",
        archive,
        "-C",
        ROOT
    ]);

    fs.unlinkSync(archive);

    fs.mkdirSync(path.join(ROOT, "root"), {
        recursive: true
    });

    fs.mkdirSync(path.join(ROOT, "tmp"), {
        recursive: true
    });

    fs.chmodSync(
        path.join(ROOT, "tmp"),
        0o1777
    );

    fs.writeFileSync(marker, "ready");

    log("Ubuntu berhasil dipasang.");
}

async function installPackages() {
    const marker = path.join(
        ROOT,
        ".packages-ready"
    );

    if (fs.existsSync(marker)) {
        log("Paket Ubuntu sudah tersedia.");
        return;
    }

    log("Menjalankan apt update...");

    await guest([
        "/usr/bin/apt-get",
        "update"
    ]);

    log("Menginstall paket Ubuntu...");

    await guest([
        "/usr/bin/apt-get",
        "install",
        "-y",
        "ca-certificates",
        "curl",
        "wget",
        "git",
        "nano",
        "vim",
        "sudo",
        "python3",
        "python3-pip",
        "python3-venv",
        "build-essential",
        "procps",
        "iproute2",
        "unzip",
        "zip",
        "tar",
        "gzip",
        "xz-utils",
        "openssh-client",
        "dnsutils"
    ]);

    fs.writeFileSync(marker, "ready");

    log("Paket berhasil diinstall.");
}

async function installCodeServer() {
    const codeDir = path.join(
        ROOT,
        "opt",
        `code-server-${CODE_VERSION}-linux-amd64`
    );

    const codeBinary = path.join(
        codeDir,
        "bin",
        "code-server"
    );

    if (fs.existsSync(codeBinary)) {
        log("Code-server sudah terpasang.");
        return codeBinary;
    }

    const archive = path.join(
        BASE,
        "code-server.tar.gz"
    );

    const url =
        `https://github.com/coder/code-server/releases/download/v${CODE_VERSION}/code-server-${CODE_VERSION}-linux-amd64.tar.gz`;

    log("Mengunduh code-server...");

    await download(url, archive);

    fs.mkdirSync(path.join(ROOT, "opt"), {
        recursive: true
    });

    log("Mengekstrak code-server...");

    await run("tar", [
        "-xzf",
        archive,
        "-C",
        path.join(ROOT, "opt")
    ]);

    fs.unlinkSync(archive);

    if (!fs.existsSync(codeBinary)) {
        throw new Error(
            "File code-server tidak ditemukan."
        );
    }

    log("Code-server berhasil dipasang.");

    return codeBinary;
}

async function startServer(config) {
    const arch = detectArchitecture();

    console.log("");
    console.log("Arsitektur terdeteksi:", arch);

    if (arch !== "amd64") {
        console.log(
            "Arsitektur belum didukung oleh binary PRoot ini."
        );
        return;
    }

    try {
        ensureDirectories();

        await installProot();
        await installUbuntu(config);
        await installPackages();

        const codeBinary = await installCodeServer();

        console.log("");
        console.log("==================================");
        console.log("       CODE SERVER STARTING");
        console.log("==================================");
        console.log(`Ubuntu    : ${config.ubuntu}`);
        console.log(`Port      : ${config.port}`);
        console.log("Workspace : /workspace");
        console.log("==================================");

        console.log(
            "Code-server sedang dijalankan..."
        );

        console.log(
            "Hentikan proses untuk kembali ke menu manager."
        );

        console.log("");

        await run(
            PROOT,
            prootArgs([
                codeBinary.replace(ROOT, ""),
                "--bind-addr",
                `0.0.0.0:${config.port}`,
                "--auth",
                "password",
                "/workspace"
            ]),
            {
                env: {
                    ...process.env,
                    HOME: "/root",
                    USER: "root",
                    PASSWORD: config.password
                }
            }
        );

    } catch (error) {
        console.log("");
        console.log("[ERROR]", error.message);
    }
}

async function resetUbuntu(config) {
    console.log("");
    console.log("========== RESET UBUNTU ==========");
    console.log("Reset akan menghapus instalasi Ubuntu.");
    console.log("Folder /workspace TIDAK akan dihapus.");
    console.log("Password dan port tetap tersimpan.");

    const confirm = await ask(
        "Ketik RESET untuk melanjutkan: "
    );

    if (confirm !== "RESET") {
        console.log("Reset dibatalkan.");
        return config;
    }

    const version = await chooseUbuntu(
        config.ubuntu
    );

    if (fs.existsSync(ROOT)) {
        fs.rmSync(ROOT, {
            recursive: true,
            force: true
        });
    }

    config.ubuntu = version;

    saveConfig(config);

    console.log("");
    console.log("Ubuntu berhasil direset.");
    console.log("Versi baru:", version);

    return config;
}

async function changeConfiguration(config) {
    console.log("");
    console.log("========== CONFIGURATION ==========");

    const password = await askPassword(
        config.password
    );

    const port = await askPort(config.port);

    const version = await chooseUbuntu(
        config.ubuntu
    );

    if (version !== config.ubuntu) {
        console.log("");
        console.log("Versi Ubuntu berubah.");
        console.log("RootFS lama perlu dihapus.");

        const confirm = await ask(
            "Ketik RESET untuk mengganti Ubuntu: "
        );

        if (confirm !== "RESET") {
            console.log("Perubahan versi dibatalkan.");
            return config;
        }

        if (fs.existsSync(ROOT)) {
            fs.rmSync(ROOT, {
                recursive: true,
                force: true
            });
        }

        config.ubuntu = version;
    }

    config.password = password;
    config.port = port;

    saveConfig(config);

    console.log("");
    console.log("Konfigurasi berhasil diperbarui.");

    return config;
}

async function mainMenu(config) {
    while (true) {
        console.log("");
        console.log("==================================");
        console.log("        UBUNTU SERVER MANAGER");
        console.log("==================================");
        console.log(`Ubuntu: ${config.ubuntu}`);
        console.log(`Port  : ${config.port}`);
        console.log("----------------------------------");
        console.log("[1] START UBUNTU + CODE SERVER");
        console.log("[2] RESET UBUNTU");
        console.log("[3] CHANGE CONFIGURATION");
        console.log("[4] EXIT");
        console.log("==================================");

        const choice = await ask("Pilih menu: ");

        switch (choice) {
            case "1":
                await startServer(config);
                break;

            case "2":
                config = await resetUbuntu(config);
                break;

            case "3":
                config = await changeConfiguration(config);
                break;

            case "4":
                console.log("Manager dihentikan.");
                rl.close();
                process.exit(0);

            default:
                console.log("Pilihan tidak valid.");
        }
    }
}

async function main() {
    ensureDirectories();

    console.log("");
    console.log("==================================");
    console.log("       NODE.JS UBUNTU MANAGER");
    console.log("==================================");

    const arch = detectArchitecture();

    console.log("Detected architecture:", arch);

    if (arch !== "amd64") {
        console.log("");
        console.log("Maaf, arsitektur belum didukung.");
        console.log("Dibutuhkan AMD64 / x86_64.");
        process.exit(1);
    }

    let config = loadConfig();

    if (
        !config ||
        !UBUNTU[config.ubuntu] ||
        !config.password ||
        !config.port
    ) {
        console.log("");
        console.log("Setup pertama kali terdeteksi.");

        config = await firstSetup();

        await startServer(config);
    }

    await mainMenu(config);
}

main().catch(error => {
    console.error("");
    console.error("FATAL ERROR:", error);
    process.exit(1);
});
