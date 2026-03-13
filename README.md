\# 🪟 Auto Installer Windows Server for VPS



\[!\[License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

\[!\[Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)

\[!\[Windows](https://img.shields.io/badge/Windows-Server%202022%20%7C%202012-blue)](https://www.microsoft.com/windows-server)



Script bash otomatis untuk menginstall \*\*Windows Server 2022\*\* dan \*\*Windows Server 2012 R2\*\* di VPS (Virtual Private Server) dengan mudah dan cepat.



!\[Windows Server Banner](https://img.shields.io/badge/Windows%20Server-Auto%20Installer-00A4EF?style=for-the-badge\&logo=windows\&logoColor=white)



\---



\## ✨ Fitur



\- 🚀 \*\*Dua Versi Windows\*\* - Pilih antara Windows Server 2022 atau 2012 R2

\- ⚡ \*\*Unattended Installation\*\* - Instalasi otomatis tanpa intervensi manual

\- 🖥️ \*\*KVM/QEMU Virtualization\*\* - Full virtualization dengan performa optimal

\- 🔌 \*\*Auto Port Forwarding\*\* - RDP (3389) dan VNC (5900) siap pakai

\- 🔄 \*\*Systemd Integration\*\* - Auto-start saat VPS reboot

\- 📊 \*\*Logging\*\* - Progress tracking dengan log detail

\- 🛡️ \*\*Secure Default\*\* - Password kuat auto-generated



\---



\## 📋 Persyaratan Sistem



| Komponen | Minimum | Direkomendasikan |

|----------|---------|------------------|

| \*\*OS Host\*\* | Ubuntu 20.04/22.04, Debian 11/12 | Ubuntu 22.04 LTS |

| \*\*Architecture\*\* | x86\_64 (64-bit) | x86\_64 |

| \*\*RAM\*\* | 2 GB | 4 GB+ |

| \*\*Disk\*\* | 25 GB free | 50 GB+ SSD |

| \*\*Virtualization\*\* | KVM Support | Full KVM/Nested VT-x |

| \*\*Network\*\* | Internet connection | 100 Mbps+ |



\### VPS Provider yang Kompatibel



| Provider | Status | Catatan |

|----------|--------|---------|

| \*\*DigitalOcean\*\* | ⚠️ Partial | Butuh nested virtualization enabled |

| \*\*Vultr\*\* | ✅ Full Support | Bare metal recommended |

| \*\*Hetzner\*\* | ✅ Full Support | Dedicated servers work best |

| \*\*AWS EC2\*\* | ⚠️ Partial | Gunakan instance dengan Nitro |

| \*\*Google Cloud\*\* | ⚠️ Partial | Butuh lisensi BYOL |

| \*\*Azure\*\* | ❌ Not Needed | Gunakan Windows VM langsung |



\---



\## 🚀 Instalasi Cepat



\### 1. Download Script



```bash

\# Clone repository

git clone https://github.com/username/windows-server-auto-installer.git

cd windows-server-auto-installer



\# Atau download langsung

wget https://raw.githubusercontent.com/username/windows-server-auto-installer/main/install-windows.sh

