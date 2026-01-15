<div align="center">

# 🐳 DockerOS Toolkit
### The Ultimate VPS Automation & OS Manager
**By Manz4VPS**

[![GitHub stars](https://img.shields.io/github/stars/manz4vps/DockerOS?style=for-the-badge&color=yellow)](https://github.com/manz4vps/DockerOS/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/manz4vps/DockerOS?style=for-the-badge&color=orange)](https://github.com/manz4vps/DockerOS/network)
[![GitHub issues](https://img.shields.io/github/issues/manz4vps/DockerOS?style=for-the-badge&color=red)](https://github.com/manz4vps/DockerOS/issues)
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)

<p align="center">
  <a href="#-installation">🚀 Install Now</a> •
  <a href="#-features">🔥 Features</a> •
  <a href="#-credits">🤝 Credits</a>
</p>

</div>

---

## 📖 About The Project

**DockerOS** adalah toolkit automasi *all-in-one* untuk manajemen VPS. Dirancang khusus untuk **DevOps**, **Game Server Owners**, dan pengguna VPS yang butuh setup cepat.

Stop buang waktu install manual! Script ini menangani:
* ✅ **Install VPS** tanpa panel hosting.
* ✅ **Setup Windows RDP** di VPS Linux.
* ✅ **Auto Install Game Panel** (Pterodactyl).
* ✅ **Docker Management** yang simpel.

---

## 🔥 Features

| Feature | Description | Status |
| :--- | :--- | :---: |
| **🐧 OS Reinstaller** | Auto install Ubuntu 22/24, Debian 11/12 | ✅ |
| **🪟 Windows on VPS** | Install Windows Server (QEMU/KVM) | ✅ |
| **🎮 Panel Installer** | Setup Game Panel & Web Panel otomatis | ✅ |
| **🐳 Docker Tools** | Build, Push, & Manage Docker Images | ✅ |

---

## 🚀 Installation

Pastikan kamu sudah login sebagai **root**.

### 1️⃣ VM Repository Link
Simpan link ini untuk referensi setup VM:
```bash
https://github.com/manz4vps/vm
```

### 2️⃣ Install OS  (POPULAR 🔥)
Gunakan command ini untuk meinstall OS VPS kamu (Ubuntu/Debian):
```bash
bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/PilihOS-vps.sh)
```

### 3️⃣ Auto Install Panel
Script otomatis untuk setup panel manajemen server:
```bash
bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/all-autoinstaller.sh)
```

### 4️⃣ Install Windows
Ubah VPS Linux menjadi RDP Windows dengan satu perintah:
```bash
bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/Scrip/install-windows.sh)
```

---

## 📋 Prerequisites

* **System:** VPS / Dedicated Server
* **Virtualization:** KVM (Recommended for Windows)
* **Architecture:** `amd64` (x86_64) or `arm64`
* **Connectivity:** Stable Internet Connection

---

## 🤝 Credits

Project ini dikembangkan dan dimaintain oleh:

<div align="center">

### [Manz4VPS](https://github.com/manz4vps)

[![Github](https://img.shields.io/badge/Github-Manz4VPS-black?style=flat&logo=github)](https://github.com/manz4vps)

</div>

Special thanks to the open-source community! 🚀

---

<div align="center">
  <small><i>Note: This script is intended for educational and experimental purposes. Use it responsibly.</i></small>
</div>
