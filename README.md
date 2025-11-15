# 🐧 Arch Linux Post-Installation Script

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.0.0-blue.svg?style=for-the-badge)](https://github.com/EmanuProds/arch-linux-pi)

A modern, interactive post-installation automation script for Arch Linux systems with comprehensive setup capabilities. 🚀

## ✨ Features

- **Interactive Menus**: User-friendly dialog-based interface for component selection
- **Modular Design**: Clean, maintainable code with separate functions for each component
- **Error Handling**: Comprehensive validation and error recovery
- **Modern Practices**: Uses Bash best practices with proper error handling
- **Comprehensive Setup**: Covers system configuration, graphics, development tools, applications, gaming, and virtualization
- **Automatic GPU Detection**: Automatically detects and installs appropriate graphics drivers
- **Backup System**: Creates backups of configuration files before modification
- **Logging**: Detailed logging with color-coded output

## 🔧 Components

### ⚙️ 1. System Configuration *(Priority Setup)*
- Pacman configuration (multilib, colors, mirrors, Chaotic-AUR repo)
- AUR helper installation (paru)
- System locales setup (en_US, pt_BR)
- **Snapper BTRFS snapshots** (automatic backups after pacman updates)
- Essential services (Bluetooth, CUPS, printer/scanner support)
- **CachyOS Kernel** (performance optimized with intelligent boot recovery)
- **Perfect Quiet Boot** (Arch splash + Plymouth spinner + GDM)
- Secure Boot setup (sbctl)

### 🎨 2. Graphics & Display
- Automatic GPU detection and driver installation (NVIDIA/AMD/Intel)
- Theme and icon setup (Adwaita themes, custom colors)
- systemd-boot splash logo
- GDM login screen logo

### 💻 3. Development Tools
- Terminal customization (fish shell, Starship prompt)
- Development packages (docker, JDK, node.js, python, etc.)
- Version managers (MISE for Node/Python/Ruby/**Go**, SDKMAN for Java)
- Modern terminal utilities (bat, exa, ripgrep, fd, fzf, jq, ncdu, tldr)
- Development tools (Scrcpy, ADB, wirless/android tools)
- IDEs and editors (VS Codium, Zed, various web dev tools)

### 📱 4. Applications
- **System utilities**: fastfetch, gparted, deja-dup, btrfs-assistant
- **Multimedia**: pitivi, sunshine, ffmpeg codecs, gst-plugins suite
- **Printing**: Complete CUPS setup with drivers and PPDs
- **Filesystem tools**: ntfs-3g, samba-client, compression tools
- **Fonts**: Source Code Pro, JetBrains Mono, Noto fonts, Adobe fonts
- **Flatpak applications (~20 apps)**: Browsers, communication, dev tools, multimedia, gaming, utilities

### 🎮 5. Gaming
- Gaming meta package
- Wine and Proton setup
- Steam installation

### 🖥️ 6. Virtualization
- GNOME Boxes with QEMU and libvirt
- Winboat Windows containers
- Hardware virtualization support

### 🛠️ 7. System Enhancements *(Performance & Automation)*
- **Zswap Compressed Swap**: Dynamic RAM compression (4-64GB, default 20GB)
- **Automated system updates** (cron-based weekly with retry logic)
- DNSMasq local DNS caching
- EarlyOOM memory management
- Microsoft CoreFonts (AUR)
- Split-lock mitigation disabler
- **Smart Flatpak HW-Acceleration** (auto-detect: AMD/Intel/NVIDIA)
- Topgrade with Paru AUR support
- CachyOS systemd optimizations

### 🔩 GNOME Menu Organization *(User Experience)*
- **Automatic menu organization** with 9 custom categorized folders
- **Smart application detection** (native + Flatpak apps)
- **Folder categories**: Android, Workflow, Containers, Office, Media Edit, Games, Utilities, Tools, System
- **Main menu preservation** for essential apps (browsers, Software Center, messaging apps)
- **Category intelligence** using GNOME Categories mapping
- **Automatic assignment** based on app metadata

### 🔧 8. GNOME Extensions *(User Experience)*
- 15+ preferred extensions for Arch Linux
- Auto Power Profile, Arch Update Indicator, Bluetooth Battery Meter
- Caffeine, GSConnect, System Monitor and more
- Automatic installation via gnome-extensions-cli

### ⚡ 9. Complete Setup (All Components)
- **Complete automation** of all components above
- **Optimized installation order** following script logic
- **Bulk execution** for clean Arch installations

## 🚀 Usage

### Interactive Mode (Recommended)
```bash
./archPI
```

### Command Line Options
```bash
./archPI --help     # 📖 Show help message
./archPI --version  # 🔢 Show version information
```

## 📦 Installation

### 🔧 Quick Install (One Command)
For fresh Arch Linux installations, use this one-liner:

```bash
# Quick install - clone and run automatically
curl -fsSL https://raw.githubusercontent.com/EmanuProds/arch-linux-pi/main/install.sh | bash

# Alternative: Manual git clone + run
git clone https://github.com/EmanuProds/arch-linux-pi.git && cd arch-linux-pi && chmod +x archPI && ./archPI
```

### 🐧 Manual Installation

1. Clone or download the repository
2. Make the script executable: `chmod +x archPI`
3. Run the script: `./archPI`
4. Follow the interactive menus to select components

## 📁 Project Structure

```
.
├── archPI                 # Main script (interactive installer)
├── install.sh            # Quick install script (curl | bash compatible)
└─── assets/               # Configuration assets
    ├── .bash_aliases     # Custom shell aliases
    ├── .bashrc          # Bash shell configuration
    └── logo/            # Logo and branding assets
        ├── boot/        # Boot splash logos
        │   └── splash-arch.bmp
        └── gdm/         # GDM login screen logos
        └── archlinux-gdm.png
```

## 🛡️ Safety Features

- **Backup Creation**: All modified configuration files are backed up automatically
- **Dependency Checks**: Verifies required tools before execution
- **Error Recovery**: Graceful handling of installation failures with detailed logging
- **User Confirmation**: Prompts for confirmation on major operations
- **Non-Root Execution**: Prevents running as root for user-specific operations
- **GNOME Extensions Auto-Installation**: 15+ extensions installed automatically
- **Single sudo Authentication**: Script requests sudo password once and caches it for the entire session

## ⚠️ Important Notes

- **Backup First**: Always backup important data before running post-installation scripts
- **Reboot Required**: Some changes (boot, graphics, services) require system reboot
- **Sudo Authentication**: Script requests password once at start and caches it for entire session
- **GNOME Extensions**: Preferred extensions are installed automatically during setup
- **Testing**: Script tested on Arch Linux with GNOME desktop (may work on others)
- **AUR Packages**: AUR packages installed using paru (AUR helper)
- **Graphics Drivers**: GPU automatically detected and appropriate drivers installed
- **Virtualization**: Requires hardware virtualization support in BIOS/UEFI
- **System Updates**: Automated weekly updates with retry logic (configurable)
- **Secure Boot**: Advanced configuration - backup your system first
- **Flatpak Apps**: ~20 applications across multiple categories installed automatically
