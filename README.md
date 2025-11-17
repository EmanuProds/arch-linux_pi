# 🐧 Arch Linux Post-Installation Script

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.1.0-blue.svg?style=for-the-badge)](https://github.com/EmanuProds/arch-linux-pi)

A modern, interactive post-installation automation script for Arch Linux systems with comprehensive setup capabilities. 🚀

## ✨ Features

- **User Configurable Constants**: Easily modify package lists and settings at the top of the script
- **Interactive Menus**: User-friendly dialog-based interface for component selection
- **Modern Practices**: Uses Bash best practices with proper error handling
- **Comprehensive Setup**: Covers system configuration, graphics, development tools, applications, gaming, and virtualization
- **Automatic GPU Detection**: Automatically detects and installs appropriate graphics drivers
- **Backup System**: Creates backups of configuration files before modification
- **Logging**: Detailed logging with color-coded output to ~/.archPI/archpi.log

## 🎛️ Customization

The script includes user-configurable constants at the top of the file for easy customization:

```bash
# System dependencies (required for script operation)
readonly DEPENDENCIES=(...)

# Package lists by category
readonly SYSTEM_UTILITIES=(...)
readonly FLATPAK_BROWSERS=(...)
readonly GAMING_PACKAGES=(...)
# ... and many more
```

**To customize:**
1. Open `archPI.sh` in your text editor
2. Modify the constants at the top of the file
3. Save and run the script as usual

This allows you to add/remove packages, change default settings, and adapt the script to your specific needs without modifying the core logic.

## 🔧 Components

### ⚙️ 1. System Configuration *(Priority Setup)*
- Pacman configuration (multilib, colors, ParallelDownloads=15, CleanMethod=KeepCurrent, Chaotic-AUR repo)
- Reflector mirror optimization (country-based selection with fallbacks)
- AUR helper installation (paru)
- System locales setup (interactive selection: en_US, pt_BR, etc.)
- **Snapper BTRFS snapshots** (automatic timeline + pre/post update snapshots)
- Essential services (Bluetooth, CUPS, printer/scanner support)
- **CachyOS Kernel** (performance optimized with emergency fallback)
- Arch Linux splash logo for boot
- **Perfect Quiet Boot** (Arch splash + Plymouth spinner + GDM)
- Secure Boot setup (sbctl with key generation and signing)
- Automatic GPU detection and driver installation (NVIDIA/AMD/Intel/Generic)
- Hardware acceleration setup for Flatpak applications
- **Zswap Compressed Swap**: Dynamic RAM compression (configurable size, default 20GB)
- DNSMasq local DNS caching (1.1.1.1, 8.8.8.8)
- EarlyOOM memory management (aggressive OOM killing)
- Microsoft CoreFonts (AUR)
- Split-lock mitigation disabler
- Topgrade system updater with Paru AUR support

### 🛠️ 2. Development Tools
- ZSH shell with Oh-My-Zsh and fish-like plugins (autosuggestions, syntax highlighting)
- Starship prompt
- Development packages (Docker, Node.js, Python, JDK, GitHub CLI, etc.)
- Version managers (MISE for Node/Python/Ruby/Go, SDKMAN for Java)
- Modern terminal utilities (bat, eza, ripgrep, fd, fzf, jq, ncdu, tldr, man-db)
- Development tools (Scrcpy, ADB, wireless/Android tools, Tailscale, etc.)
- IDEs and editors (VS Codium, Zed, Android Studio, Podman Desktop, etc.)
- QEMU/KVM with GNOME Boxes
- Hardware virtualization support
- User group configuration for libvirt access

### 📱 3. Applications & Utilities
- LizardByte repository (for Sunshine game streaming)
- **System utilities**: fastfetch, gparted, deja-dup, btrfs-assistant, android-tools, etc.
- **Multimedia**: pitivi, sunshine, ffmpeg codecs, gst-plugins suite
- **Printing**: Complete CUPS setup with drivers and PPDs
- **Filesystem tools**: ntfs-3g, samba-client, compression tools (unrar, unzip, p7zip, etc.)
- **Fonts**: Adobe Source Code Pro, DejaVu, Noto fonts, Fira Code, JetBrains Mono, etc.
- **Flatpak applications (~25+ apps)**: Browsers, communication, dev tools, multimedia, gaming, utilities
- Gaming packages (Steam, Wine, Proton, GameMode, MangoHud, Gamescope)
- Arch gaming meta package integration
- Performance optimizations for gaming

### 🎨 4. Themes & Optimization
- GNOME themes and icons (Adwaita, morewaita-icon-theme)
- GNOME extensions (15+ extensions for GNOME 49 compatibility)
- GTK theme configuration
- Remove unnecessary GNOME packages
- Hide unused applications from GNOME menu
- Menu organization with categorized folders
- System optimization and cleanup

### ⚡ 5. Complete Setup (All Components)
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
git clone https://github.com/EmanuProds/arch-linux_pi.git && cd arch-linux-pi && chmod +x archPI && ./archPI
```

## 📁 Project Structure

```
.
├── archPI.sh             # Main script (interactive installer)
├── README.md            # This documentation file
└── assets/              # Configuration assets (logos, themes)
    └── logo/           # Logo and branding assets
        ├── boot/       # Boot splash logos
        └───└── splash-arch.bmp
```

## 🛡️ Safety Features

- **Dependency Checks**: Verifies required tools (dialog, curl, git) before execution
- **Error Recovery**: Graceful handling of installation failures with detailed logging to ~/.archPI/archpi.log
- **User Confirmation**: Interactive confirmation dialogs for major operations
- **Sudo Keep-Alive**: Single sudo authentication cached for entire session

## ⚠️ Important Notes

- **Reboot Required**: Some changes (kernel, boot, graphics, services) require system reboot
- **Virtualization**: Requires hardware virtualization support in BIOS/UEFI
- **Zswap**: Compressed RAM swap (configurable size, default 20GB)
- **DNS Caching**: Local DNS caching with DNSMasq for improved performance
- **Testing**: Script tested on Arch Linux with GNOME desktop (may work on others)
