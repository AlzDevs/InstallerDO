# 🪟 Windows Server Auto Installer for VPS

Script **Bash otomatis** untuk menginstall **Windows Server 2022** atau **Windows Server 2012 R2** di VPS menggunakan **KVM/QEMU virtualization**.

![Windows](https://img.shields.io/badge/Windows-Server%202022%20%7C%202012-blue?logo=windows)
![Platform](https://img.shields.io/badge/Platform-Linux-blue)
![License](https://img.shields.io/badge/License-MIT-yellow)

---

## ✨ Features

- Install **Windows Server 2022** atau **Windows Server 2012 R2**
- **Unattended installation** (otomatis)
- Virtualization menggunakan **KVM / QEMU**
- **RDP (3389)** dan **VNC (5900)** otomatis aktif
- **Auto start** saat VPS reboot
- **Auto-generated Windows password**

---

## 📋 Requirements

| Komponen | Minimum |
|--------|--------|
| OS | Ubuntu 20.04+ / Debian 11+ |
| CPU | x86_64 |
| RAM | 2 GB |
| Disk | 25 GB free |
| Virtualization | KVM Support |

Cek dukungan KVM:

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
