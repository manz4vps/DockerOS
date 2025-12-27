# 🚀 VPS & Docker OS Toolkit

## Overview

Toolkit ini berisi kumpulan command untuk build Docker image, install OS, pasang panel, tunnel Playit, dan Cloudflare token.  
Semua sudah dirapikan supaya gampang copy-paste dan cepat dipakai di VPS.

## Prerequisites

- VPS atau server dengan Docker terinstal
- Internet connectivity
- Bash shell environment
- CPU architecture: x86_64 (amd64) atau aarch64 (arm64)
- Akses akun Docker Hub (untuk push image)

## 🛠️ Installation
   **COPY**
   ```sh
   https://github.com/manz4vps/vm
   ```
1. **VPS IDX GOOGLE:**

    ```sh
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/vps-idx.sh)
    ```

5. **Install OS di VPS:**

    ```sh
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/PilihOS-vps.sh)
    ```

    
6. **Install Panel:**

    ```sh
    bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/all-autoinstaller.sh)
    ```
    
7. **Windows-install**
   ```sh
   bash <(curl -s https://raw.githubusercontent.com/manz4vps/DockerOS/refs/heads/main/install-windows.sh)
   ```

# Supported Architectures

- OS (ubuntu24)
- OS (ubuntu22)
- OS (debian12)
- OS (debian11)
- OS (windows)

# License

This VPS & Docker OS Toolkit is released under the [MIT License](LICENSE).

# Credits

Developed and maintained by **manz4vps**  
Special thanks to the open-source community and contributors 🚀

---

**Note:** This script is intended for educationalnd experimental purposes. Use it responsibly and at your own risk.
