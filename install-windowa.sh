#!/bin/bash
# ============================================
# Auto Installer Windows Server untuk VPS DO
# Supports: Windows Server 2022 & 2012 R2
# ============================================

set -e

# Warna untuk output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Konfigurasi
WINDOWS_2022_ISO="https://software-static.download.prss.microsoft.com/sg/download/888969d5-f34g-4e03-ac9d-1f9786c66749/SERVER_EVAL_x64FRE_en-us.iso"
WINDOWS_2012_ISO="https://download.microsoft.com/download/6/2/A/62A76ABB-9990-4EFC-A4FE-C7D698D4C57D/windowsserver2012r2.iso"
TEMP_DIR="/root/windows-install"
LOG_FILE="/var/log/windows-installer.log"

# Fungsi logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

# Banner
show_banner() {
    clear
    echo -e "${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║           AUTO INSTALLER WINDOWS SERVER VPS DO               ║"
    echo "║                    by Kimi AI Assistant                      ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Cek root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Script harus dijalankan sebagai root!"
    fi
}

# Cek sistem
check_system() {
    log "Memeriksa sistem..."
    
    # Cek architecture
    ARCH=$(uname -m)
    if [[ "$ARCH" != "x86_64" ]]; then
        error "Architecture $ARCH tidak didukung. Harus x86_64."
    fi
    
    # Cek RAM minimal 2GB
    RAM=$(free -m | awk '/^Mem:/{print $2}')
    if [[ "$RAM" -lt 2048 ]]; then
        warning "RAM kurang dari 2GB ($RAM MB). Windows Server mungkin tidak berjalan optimal."
    fi
    
    # Cek disk space minimal 20GB
    DISK=$(df / | tail -1 | awk '{print $4}')
    if [[ "$DISK" -lt 20971520 ]]; then
        error "Disk space tidak cukup. Minimal 20GB dibutuhkan."
    fi
    
    log "Sistem memenuhi syarat ✓"
}

# Install dependencies
install_deps() {
    log "Menginstall dependencies..."
    
    apt-get update -qq
    
    # Install tools yang dibutuhkan
    apt-get install -y -qq \
        wget \
        curl \
        qemu-kvm \
        qemu-utils \
        virt-manager \
        libvirt-daemon-system \
        bridge-utils \
        genisoimage \
        xz-utils \
        aria2 \
        ntfs-3g \
        wimtools \
        chntpw \
        || error "Gagal menginstall dependencies"
    
    # Enable KVM
    modprobe kvm
    modprobe kvm_intel || modprobe kvm_amd
    
    log "Dependencies terinstall ✓"
}

# Pilih versi Windows
select_version() {
    echo ""
    echo -e "${YELLOW}Pilih versi Windows Server:${NC}"
    echo "1) Windows Server 2022 (Recommended)"
    echo "2) Windows Server 2012 R2"
    echo ""
    read -p "Pilihan [1-2]: " choice
    
    case $choice in
        1)
            WINDOWS_VERSION="2022"
            ISO_URL="$WINDOWS_2022_ISO"
            ISO_NAME="windows2022.iso"
            ;;
        2)
            WINDOWS_VERSION="2012"
            ISO_URL="$WINDOWS_2012_ISO"
            ISO_NAME="windows2012.iso"
            ;;
        *)
            error "Pilihan tidak valid!"
            ;;
    esac
    
    log "Versi terpilih: Windows Server $WINDOWS_VERSION"
}

# Download Windows ISO
download_iso() {
    log "Mendownload Windows Server $WINDOWS_VERSION ISO..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    if [[ -f "$ISO_NAME" ]]; then
        warning "ISO sudah ada, menggunakan file yang ada..."
    else
        log "Download dimulai, ini mungkin memakan waktu beberapa menit..."
        aria2c -x 16 -s 16 -o "$ISO_NAME" "$ISO_URL" || \
        wget --progress=bar:force -O "$ISO_NAME" "$ISO_URL" || \
        error "Gagal mendownload ISO"
    fi
    
    # Verifikasi file
    if [[ ! -f "$ISO_NAME" ]] || [[ ! -s "$ISO_NAME" ]]; then
        error "File ISO corrupt atau tidak lengkap"
    fi
    
    log "Download selesai ✓"
}

# Konfigurasi network
setup_network() {
    log "Mengkonfigurasi network..."
    
    # Detect primary interface
    PRIMARY_IF=$(ip route | grep default | awk '{print $5}' | head -n1)
    IP_ADDR=$(ip addr show $PRIMARY_IF | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    GATEWAY=$(ip route | grep default | awk '{print $3}')
    
    log "Interface: $PRIMARY_IF"
    log "IP Address: $IP_ADDR"
    log "Gateway: $GATEWAY"
}

# Buat unattended answer file
create_unattend() {
    log "Membuat konfigurasi unattended installation..."
    
    # Password default untuk Administrator
    ADMIN_PASSWORD="P@ssw0rd123!"
    
    cat > "$TEMP_DIR/autounattend.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <SetupUILanguage>
                <UILanguage>en-US</UILanguage>
            </SetupUILanguage>
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UILanguageFallback>en-US</UILanguageFallback>
            <UserLocale>en-US</UserLocale>
        </component>
        <component name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <DiskConfiguration>
                <Disk wcm:action="add">
                    <DiskID>0</DiskID>
                    <WillWipeDisk>true</WillWipeDisk>
                    <CreatePartitions>
                        <CreatePartition wcm:action="add">
                            <Order>1</Order>
                            <Type>Primary</Type>
                            <Size>100</Size>
                        </CreatePartition>
                        <CreatePartition wcm:action="add">
                            <Order>2</Order>
                            <Type>Primary</Type>
                            <Extend>true</Extend>
                        </CreatePartition>
                    </CreatePartitions>
                    <ModifyPartitions>
                        <ModifyPartition wcm:action="add">
                            <Order>1</Order>
                            <PartitionID>1</PartitionID>
                            <Label>System</Label>
                            <Format>NTFS</Format>
                            <Active>true</Active>
                        </ModifyPartition>
                        <ModifyPartition wcm:action="add">
                            <Order>2</Order>
                            <PartitionID>2</PartitionID>
                            <Label>Windows</Label>
                            <Letter>C</Letter>
                            <Format>NTFS</Format>
                        </ModifyPartition>
                    </ModifyPartitions>
                </Disk>
            </DiskConfiguration>
            <ImageInstall>
                <OSImage>
                    <InstallFrom>
                        <MetaData wcm:action="add">
                            <Key>/IMAGE/NAME</Key>
                            <Value>Windows Server 2022 SERVERSTANDARD</Value>
                        </MetaData>
                    </InstallFrom>
                    <InstallTo>
                        <DiskID>0</DiskID>
                        <PartitionID>2</PartitionID>
                    </InstallTo>
                </OSImage>
            </ImageInstall>
            <UserData>
                <ProductKey>
                    <Key></Key>
                    <WillShowUI>OnError</WillShowUI>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
                <FullName>Administrator</FullName>
                <Organization>VPS</Organization>
            </UserData>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <OOBE>
                <HideEULAPage>true</HideEULAPage>
                <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
                <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
                <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
                <NetworkLocation>Work</NetworkLocation>
                <SkipMachineOOBE>true</SkipMachineOOBE>
                <SkipUserOOBE>true</SkipUserOOBE>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>REPLACE_PASSWORD</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
            </UserAccounts>
            <TimeZone>SE Asia Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <InputLocale>en-US</InputLocale>
            <SystemLocale>en-US</SystemLocale>
            <UILanguage>en-US</UILanguage>
            <UserLocale>en-US</UserLocale>
        </component>
    </settings>
</unattend>
EOF

    # Replace password
    sed -i "s/REPLACE_PASSWORD/$ADMIN_PASSWORD/g" "$TEMP_DIR/autounattend.xml"
    
    log "Unattend config created ✓"
    log "Default Password: $ADMIN_PASSWORD"
}

# Setup disk image
setup_disk() {
    log "Membuat virtual disk..."
    cd "$TEMP_DIR"
    
    # Buat disk 25GB
    qemu-img create -f qcow2 windows-disk.qcow2 25G
    
    log "Virtual disk created (25GB) ✓"
}

# Jalankan instalasi dengan QEMU/KVM
run_installation() {
    log "Memulai instalasi Windows Server $WINDOWS_VERSION..."
    log "Ini akan memakan waktu 15-30 menit..."
    
    cd "$TEMP_DIR"
    
    # Mount ISO dan copy autounattend.xml
    mkdir -p iso_mount custom_iso
    mount -o loop "$ISO_NAME" iso_mount
    
    # Copy ISO content
    rsync -av iso_mount/ custom_iso/ 2>/dev/null || cp -r iso_mount/* custom_iso/
    
    # Copy autounattend.xml ke root ISO
    cp autounattend.xml custom_iso/
    
    # Create new ISO
    mkisofs -o windows-custom.iso -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 -boot-info-table -J -R -V "Windows Setup" custom_iso/ || \
    genisoimage -o windows-custom.iso -b boot/etfsboot.com -no-emul-boot -boot-load-size 8 -boot-info-table -J -R -V "Windows Setup" custom_iso/
    
    umount iso_mount
    
    # Jalankan QEMU dengan KVM
    log "Booting installer..."
    
    nohup qemu-system-x86_64 \
        -enable-kvm \
        -m 4096 \
        -smp 2 \
        -cpu host \
        -drive file=windows-disk.qcow2,format=qcow2,if=virtio \
        -cdrom windows-custom.iso \
        -netdev user,id=net0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5985-:5985 \
        -device virtio-net-pci,netdev=net0 \
        -vnc :0 \
        -boot d \
        > qemu.log 2>&1 &
    
    QEMU_PID=$!
    log "QEMU started with PID: $QEMU_PID"
    
    # Tunggu instalasi selesai
    log "Menunggu instalasi selesai..."
    log "Anda bisa monitor progress dengan VNC viewer ke IP:5900"
    
    # Monitor progress
    sleep 300  # Tunggu 5 menit pertama
    
    while kill -0 $QEMU_PID 2>/dev/null; do
        sleep 60
        log "Instalasi masih berjalan..."
    done
    
    log "Instalasi selesai!"
}

# Konfigurasi boot permanen
setup_boot() {
    log "Mengkonfigurasi boot permanen..."
    cd "$TEMP_DIR"
    
    # Create systemd service untuk auto-start Windows
    cat > /etc/systemd/system/windows-server.service << EOF
[Unit]
Description=Windows Server VM
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -cpu host \
    -drive file=$TEMP_DIR/windows-disk.qcow2,format=qcow2,if=virtio \
    -netdev user,id=net0,hostfwd=tcp::3389-:3389,hostfwd=tcp::5985-:5985,hostfwd=tcp::22-:22 \
    -device virtio-net-pci,netdev=net0 \
    -vnc :0 \
    -boot c \
    -nographic
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable windows-server.service
    
    log "Service created ✓"
}

# Konfigurasi RDP dan network
post_install_config() {
    log "Melakukan post-install configuration..."
    
    # Install dan konfigurasi xrdp untuk bridge (opsional)
    # Atau setup port forwarding
    
    log "============================================"
    log "INSTALASI SELESAI!"
    log "============================================"
    log "Detail Akses:"
    log "  - RDP: IP_VPS:3389"
    log "  - VNC: IP_VPS:5900 (untuk monitor)"
    log "  - Username: Administrator"
    log "  - Password: P@ssw0rd123!"
    log ""
    log "Command untuk manage VM:"
    log "  systemctl start windows-server  # Start VM"
    log "  systemctl stop windows-server   # Stop VM"
    log "  systemctl status windows-server # Status VM"
    log "============================================"
}

# Fungsi untuk mode DD (alternatif)
dd_mode_install() {
    log "Menggunakan mode DD untuk instalasi langsung ke disk..."
    
    warning "Mode ini akan menghapus SELURUH data di VPS!"
    read -p "Apakah Anda yakin? (yes/no): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        log "Instalasi dibatalkan"
        exit 0
    fi
    
    # Download Windows image yang sudah jadi (pre-installed)
    # Ini lebih cepat tapi butuh image yang compatible dengan DO
    
    log "Mode DD belum diimplementasikan dengan image public."
    log "Silakan gunakan mode KVM (pilihan 1)."
}

# Menu utama
main() {
    show_banner
    check_root
    check_system
    
    echo ""
    echo "Pilih metode instalasi:"
    echo "1) KVM/QEMU (Recommended - Full Virtualization)"
    echo "2) DD Mode (Direct Disk - Experimental)"
    echo ""
    read -p "Pilihan [1-2]: " method
    
    case $method in
        1)
            install_deps
            select_version
            download_iso
            setup_network
            create_unattend
            setup_disk
            run_installation
            setup_boot
            post_install_config
            ;;
        2)
            dd_mode_install
            ;;
        *)
            error "Pilihan tidak valid!"
            ;;
    esac
}

# Jalankan
main "$@"