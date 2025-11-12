# 🐧 Arch Linux Post-Installation Script

[![Bash](https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.0.0-blue.svg?style=for-the-badge)](https://github.com/EmanuProds/Post-Installation_Arch-Linux)

A modern, interactive post-installation automation script for Arch Linux systems with comprehensive setup capabilities. 🚀

## ✨ Features

- **🖥️ Interactive Menus**: User-friendly dialog-based interface for component selection
- **🏗️ Modular Design**: Clean, maintainable code with separate functions for each component
- **🛡️ Error Handling**: Comprehensive validation and error recovery
- **⚡ Modern Practices**: Uses Bash best practices with proper error handling
- **🔧 Comprehensive Setup**: Covers system configuration, graphics, development tools, applications, gaming, and virtualization
- **🎮 Automatic GPU Detection**: Automatically detects and installs appropriate graphics drivers
- **💾 Backup System**: Creates backups of configuration files before modification
- **📝 Logging**: Detailed logging with color-coded output

## 🔧 Components

### ⚙️ System Configuration
- 🏪 Pacman configuration (multilib, colors, mirrors)
- 📦 AUR helper installation (paru)
- 🌍 System locales setup
- 🔌 Essential services (Bluetooth, CUPS)

### 🎨 Graphics & Display
- 🎮 Automatic GPU detection and driver installation
- 🎭 Theme and icon setup (Adwaita, Papirus)
- 🖱️ Custom cursor themes

### 💻 Development Tools
- 🐚 Terminal customization (Zsh, Oh My Bash)
- 🛠️ Development packages (git, GitHub CLI)
- 💾 Programming languages (Node.js, Python, Java)
- ⚡ Modern terminal utilities (bat, exa, ripgrep, etc.)

### 📱 Applications
- 🔍 System utilities (htop, fastfetch, etc.)
- 🎵 Multimedia codecs and players
- 📦 Flatpak applications (Discord, Telegram, etc.)

### 🎮 Gaming
- 🕹️ Gaming meta package
- 🍷 Wine and Proton setup
- 🚂 Steam installation

### 🖥️ Virtualization
- 🐧 QEMU and virt-manager setup
- 🔒 Libvirt configuration

### 🔧 Additional Features
- 🖥️ Qt theme configuration (qt5ct/qt6ct)
- 🖨️ Printer and scanner support (CUPS)
- 🌐 Flatpak and Flathub setup
- 🔒 Firewall configuration (firewalld)
- ⌨️ Custom Bash aliases and configuration
- 🎨 Custom logo and branding

## 📋 Requirements

- 🐧 Arch Linux system
- 🌐 Internet connection
- 🔑 sudo privileges

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

1. 📥 Clone or download the repository
2. ⚙️ Make the script executable: `chmod +x archPI`
3. ▶️ Run the script: `./archPI`
4. 📋 Follow the interactive menus to select components

## 📁 Project Structure

```
.
├── archPI                 # 🖥️ Main script
├── assets/               # 🎨 Configuration assets
│   ├── .bash_aliases     # ⌨️ Custom aliases
│   ├── .bashrc          # 🐚 Bash configuration
│   └── cursor/          # 🖱️ Custom cursor themes
├── README.md            # 📄 This file (English)
├── README.pt-BR.md      # 📄 Portuguese version
└── archPI-personal.sh   # 📜 Legacy personal script (deprecated)
```

## 🛡️ Safety Features

- **💾 Backup Creation**: All modified configuration files are backed up
- **🔍 Dependency Checks**: Verifies required tools before execution
- **🔄 Error Recovery**: Graceful handling of installation failures
- **✅ User Confirmation**: Prompts for confirmation on major operations
- **🚫 Non-Root Execution**: Prevents running as root for user operations

## 📄 License

MIT License - see repository for details.

## ⚠️ Important Notes

- **Backup First**: Always backup important data before running post-installation scripts
- **Reboot Required**: Some changes require system reboot to take effect
- **GNOME Extensions**: After setup, use Extension Manager to install recommended extensions
- **Testing**: This script has been tested on Arch Linux with GNOME desktop
- **AUR Packages**: AUR packages are installed using paru (AUR helper)
- **Graphics Drivers**: Script automatically detects GPU and installs appropriate drivers
- **Virtualization**: Requires hardware virtualization support in BIOS/UEFI
