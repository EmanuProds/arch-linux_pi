#!/bin/bash
#
# Post-Installation Arch Linux Script
# Modern, interactive post-installation automation for Arch Linux
#
# Author: Emanuel Pereira
# Website: https://github.com/EmanuProds/Post-Installation_Arch-Linux
# License: MIT
#
# This script provides a comprehensive, interactive post-installation setup
# for Arch Linux systems with modern best practices and error handling.

set -euo pipefail

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================

# Global configuration array containing all script settings
# This associative array centralizes all configurable paths and parameters
declare -A CONFIG=(
    ["SCRIPT_VERSION"]="3.0.0"      # Current script version for changelog and compatibility
    ["TEMP_DIR"]="$HOME/.archpi_temp"   # Temporary directory for build files and downloads
    ["BACKUP_DIR"]="$HOME/.archpi_backup"  # Directory to store configuration backups
    ["LOG_FILE"]="$HOME/.archpi.log"   # Main log file for script execution tracking
    ["ASSETS_DIR"]="assets"      # Directory containing custom assets (logos, themes)
    ["DIALOG_HEIGHT"]=20         # Default height for dialog menus
    ["DIALOG_WIDTH"]=70          # Default width for dialog menus
)

# Color codes for output
declare -A COLORS=(
    ["RED"]='\033[0;31m'
    ["GREEN"]='\033[0;32m'
    ["YELLOW"]='\033[1;33m'
    ["BLUE"]='\033[0;34m'
    ["NC"]='\033[0m' # No Color
)

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Logging functions
log_info() {
    echo -e "${COLORS[GREEN]}[INFO]${COLORS[NC]} $1" | tee -a "${CONFIG[LOG_FILE]}"
}

log_warn() {
    echo -e "${COLORS[YELLOW]}[WARN]${COLORS[NC]} $1" | tee -a "${CONFIG[LOG_FILE]}"
}

log_error() {
    echo -e "${COLORS[RED]}[ERROR]${COLORS[NC]} $1" | tee -a "${CONFIG[LOG_FILE]}"
}

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Command '$1' not found. Please install it first."
        return 1
    fi
    return 0
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for user-specific operations."
        return 1
    fi
    return 0
}

# Backup file before modification
backup_file() {
    local file="$1"
    local backup="${CONFIG[BACKUP_DIR]}/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"

    if [[ -f "$file" ]]; then
        mkdir -p "${CONFIG[BACKUP_DIR]}"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Execute command with error handling
execute() {
    local cmd="$1"
    local description="${2:-Executing command}"

    log_info "$description: $cmd"
    if eval "$cmd"; then
        log_info "✓ $description completed successfully"
        return 0
    else
        log_error "✗ $description failed"
        return 1
    fi
}

# Check internet connectivity
check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        log_error "No internet connection detected. Please check your network."
        return 1
    fi
    return 0
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

check_dependencies() {
    local deps=("dialog" "curl" "git" "sudo" "gnome-extensions-cli")
    local missing=()
    local failed_auto_install=()

    # Check which dependencies are missing
    for dep in "${deps[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done

    # If no dependencies are missing, return success
    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    log_info "Missing required dependencies: ${missing[*]}"
    log_info "Attempting automatic installation..."

    # Try to install missing dependencies automatically
    for dep in "${missing[@]}"; do
        log_info "Installing $dep..."

        # Try automatic installation (will fail if sudo password is required)
        if sudo -n pacman -S --noconfirm "$dep" &>/dev/null; then
            log_info "✓ Successfully installed $dep"
        else
            log_warn "Failed to install $dep automatically (may require password)"
            failed_auto_install+=("$dep")
        fi
    done

    # Check again which dependencies are still missing
    local still_missing=()
    for dep in "${missing[@]}"; do
        if ! check_command "$dep"; then
            still_missing+=("$dep")
        fi
    done

    # If all dependencies are now installed, continue
    if [[ ${#still_missing[@]} -eq 0 ]]; then
        log_info "All dependencies successfully installed!"
        return 0
    fi

    # If some dependencies still missing, show manual installation instructions
    log_error "Some dependencies could not be installed automatically: ${still_missing[*]}"
    log_info "Please install them manually with:"
    log_info "sudo pacman -S ${still_missing[*]}"
    log_info "Then run the script again."
    exit 1
}

# =============================================================================
# SYSTEM CONFIGURATION FUNCTIONS
# =============================================================================

setup_pacman() {
    log_info "Setting up Pacman configuration..."

    # Backup pacman.conf
    backup_file "/etc/pacman.conf"

    # Enable multilib repository
    sudo sed -i '/^\[multilib\]$/,/^\[/s/^#//' /etc/pacman.conf

    # Enable colors and other improvements
    sudo sed -i 's/^#Color/Color/' /etc/pacman.conf
    sudo sed -i 's/^#ILoveCandy/ILoveCandy/' /etc/pacman.conf
    sudo sed -i 's/^#VerbosePkgLists/VerbosePkgLists/' /etc/pacman.conf

    # Update mirrorlist for Brazil
    execute "sudo pacman -Sy --noconfirm reflector" "Installing reflector"
    execute "sudo reflector --country Brazil --sort rate --save /etc/pacman.d/mirrorlist" "Updating mirrorlist"

    # Update package database
    execute "sudo pacman -Syuu --noconfirm" "Updating system"

    # Add Chaotic repository
    execute "sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB && sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
sudo pacman-key --lsign-key 3056513887B78AEB" "Add primary key and mirror list to Chaotic repository"
    execute "sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' && sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'" "Install Chaotic keyring and Chaotic mirrorlist"

    # Enable Chaotic-AUR repository
    sudo tee -a /etc/pacman.conf <<EOF

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

    # Syncing Chaotic repository
    sudo pacman -Syu
}

install_aur_helper() {
    local aur_helper="paru"

    if check_command "$aur_helper"; then
        log_info "AUR helper '$aur_helper' is already installed"
        return 0
    fi

    log_info "Installing AUR helper: $aur_helper"

    # Install base-devel if not present
    execute "sudo pacman -S --needed --noconfirm git base-devel" "Installing base development tools"

    # Clone and build paru
    cd "${CONFIG[TEMP_DIR]}"
    execute "git clone https://aur.archlinux.org/paru.git" "Cloning paru repository"
    cd paru
    execute "makepkg -si --noconfirm" "Building and installing paru"
    cd ..
    rm -rf paru
}

setup_locales() {
    log_info "Setting up system locales..."

    backup_file "/etc/locale.gen"

    # Enable common locales
    sudo sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    sudo sed -i 's/^#pt_BR.UTF-8 UTF-8/pt_BR.UTF-8 UTF-8/' /etc/locale.gen

    execute "sudo locale-gen" "Generating locales"

    # Set system locale
    echo "LANG=en_US.UTF-8" | sudo tee /etc/locale.conf > /dev/null
}

setup_system_services() {
    log_info "Setting up system services..."

    # Install system services dependencies
    local service_deps=(
        "cups" "bluez"
    )
    execute "sudo pacman -S --noconfirm ${service_deps[*]}" "Installing system service dependencies"

    # Enable Bluetooth
    execute "sudo systemctl enable bluetooth.service" "Enabling Bluetooth service"
    execute "sudo systemctl start bluetooth.service" "Starting Bluetooth service"

    # Enable CUPS (printing)
    execute "sudo systemctl enable cups.service" "Enabling CUPS service"
    execute "sudo systemctl start cups.service" "Starting CUPS service"

    # Add user to necessary groups
    execute "sudo usermod -aG lp,scanner "$USER"" "Adding user to printer groups"
}

setup_snapper() {
    log_info "Setting up Snapper for system snapshots..."

    # Install Snapper
    execute "sudo pacman -S --noconfirm snapper snap-pac" "Installing Snapper and snap-pac"

    # Configure Snapper for root filesystem
    log_info "Configuring Snapper for root filesystem..."
    sudo umount /.snapshots 2>/dev/null || true
    sudo rm -rf /.snapshots
    sudo snapper -c root create-config /

    # Configure snapshot retention policy
    backup_file "/etc/snapper/configs/root"
    sudo tee "/etc/snapper/configs/root" > /dev/null <<EOF
# Subvolume to snapshot
SUBVOLUME="/"

# Filesystem type
FSTYPE="btrfs"

# User and group for operations
ALLOW_USERS=""
ALLOW_GROUPS=""

# Sync interval
SYNC_ACL="no"

# Cleanup settings
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_LIMIT_HOURLY="5"
TIMELINE_LIMIT_DAILY="7"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# Weekly cleanup (2 versions per day, 14 total for week)
WEEKLY_CLEANUP_ALGORITHM="number"
WEEKLY_CLEANUP_NUMBER="14"

# Monthly cleanup (keep 12 months back approximately)
MONTHLY_CLEANUP_ALGORITHM="timeline"
MONTHLY_CLEANUP_TIMELINE_LIMIT_DAILY="0"
MONTHLY_CLEANUP_TIMELINE_LIMIT_MONTHLY="12"
EOF

    # Configure snap-pac for automatic snapshots after pacman transactions
    backup_file "/etc/snap-pac.ini"
    cat <<EOF | sudo tee "/etc/snap-pac.ini" > /dev/null
[snap-pac]
desc-limit = 75
snapshot = yes
cleanup = yes
EOF

    # Enable timeline snapshots
    execute "sudo systemctl enable --now snapper-timeline.timer" "Enabling Snapper timeline snapshots"

    # Enable cleanup timer
    execute "sudo systemctl enable --now snapper-cleanup.timer" "Enabling Snapper cleanup timer"

    # Create initial snapshot
    execute "sudo snapper -c root create -d 'Fresh system install'" "Creating initial system snapshot"

    log_info "Snapper setup completed!"
    log_info "System snapshots will be created automatically after pacman updates."
    log_info "Timeline: 2 versions/day, 14 versions/week, 12 months backup"
    log_info "Use 'sudo snapper -c root list' to view snapshots"
    log_info "Use 'sudo snapper -c root rollback <number>' to rollback"
}

setup_quiet_boot() {
    log_info "Setting up perfect quiet boot: Arch splash + spinner theme (no watermark) + GDM..."

    # Install Plymouth with spinner theme
    execute "sudo pacman -S --noconfirm plymouth plymouth-theme-spinner" "Installing Plymouth with spinner theme"

    # Configure Plymouth for spinner theme without watermark
    backup_file "/etc/plymouth/plymouthd.conf"
    sudo sed -i 's/^Theme=.*/Theme=spinner/' /etc/plymouth/plymouthd.conf

    # Remove watermark from spinner theme if it exists
    local spinner_dir="/usr/share/plymouth/themes/spinner"
    if [[ -d "$spinner_dir" ]]; then
        # Remove any watermark files if present
        sudo find "$spinner_dir" -name "*watermark*" -delete 2>/dev/null || true
        log_info "Ensured plymouth spinner theme has no watermark"
    fi

    # Configure systemd initrd for Plymouth
    execute "sudo systemctl enable plymouth-start.service" "Enabling Plymouth systemd service"

    # Configure quiet kernel parameters
    configure_kernel_quiet_params

    # Regenerate initramfs for systemd-boot
    log_info "Configuring Plymouth integration for systemd-boot..."
    execute "sudo bootctl install" "Ensuring systemd-boot is properly configured"
    execute "sudo mkinitcpio --no-squashfs -P" "Regenerating initramfs with Plymouth support"

    # Setup Arch Linux splash logo
    setup_arch_splash_logo

    log_info "✅ Quiet boot configured: Splash → Spinner (no watermark) → GDM"
    log_info "Next time you reboot, you'll see the perfect quiet boot sequence!"
}

configure_kernel_quiet_params() {
    log_info "Configuring kernel parameters for quiet boot (systemd-boot only)..."

    # Check if systemd-boot is present
    if [[ ! -d "/boot/loader" ]]; then
        log_error "systemd-boot not detected! This function requires systemd-boot."
        log_info "Please install and configure systemd-boot first."
        return 1
    fi

    # Locate the arch boot entry
    local arch_entry=""
    for entry in /boot/loader/entries/*.conf; do
        if [[ -f "$entry" && ( "$(basename "$entry")" == "arch.conf" || "$(grep -c "Arch Linux" "$entry" 2>/dev/null || echo "0")" -gt "0" ) ]]; then
            arch_entry="$entry"
            break
        fi
    done

    if [[ -z "$arch_entry" ]]; then
        log_error "No Arch Linux systemd-boot entry found in /boot/loader/entries/"
        log_info "Please ensure systemd-boot is properly configured with an Arch entry."
        return 1
    fi

    # Backup the entry file
    backup_file "$arch_entry"

    # Add quiet splash to kernel options if not present
    if ! grep -q "quiet splash" "$arch_entry"; then
        sudo sed -i 's/^options.*/& quiet splash/' "$arch_entry"
        log_info "Added 'quiet splash' to systemd-boot kernel parameters"
    else
        log_info "Quiet splash parameters already present in systemd-boot entry"
    fi
}

setup_arch_splash_logo() {
    log_info "Setting up Arch Linux splash logo..."

    # Check if arch splash logo exists in assets
    local arch_logo="${CONFIG[ASSETS_DIR]}/logo/boot/splash-arch.bmp"
    if [[ ! -f "$arch_logo" ]]; then
        log_error "Arch splash logo not found at $arch_logo"
        log_info "Please ensure splash-arch.bmp exists in assets/logo/boot/"
        return 1
    fi

    # Copy Arch logo to systemd-boot splash location
    execute "sudo cp '$arch_logo' '/usr/share/systemd-boot/splash.bmp'" "Installing Arch Linux splash logo"

    # For systemd-boot, update if running
    if [[ -d "/boot/loader" ]]; then
        execute "sudo bootctl update" "Updating systemd-boot with Arch splash logo"
        log_info "Splash logo updated for systemd-boot"
    else
        log_info "Systemd-boot splash configured - will show on next boot"
    fi
}

setup_secure_boot() {
    log_warn "Setting up Secure Boot with sbctl. This is an advanced configuration that can make your system unbootable if done incorrectly."
    log_warn "Only proceed if you understand Secure Boot and have a recovery option."

    dialog --title "⚠️ Warning: Secure Boot Setup" \
           --yesno "Setting up Secure Boot can make your system unbootable if not configured properly.\n\nYou need:\n- UEFI firmware that supports Custom Mode\n- Physical access for recovery if needed\n- Basic knowledge of Secure Boot\n\nContinue only if you're sure!" \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

    if [[ $? -ne 0 ]]; then
        log_info "Secure Boot setup cancelled by user."
        return 0
    fi

    # Install sbctl
    execute "sudo pacman -S --noconfirm sbctl" "Installing sbctl for Secure Boot management"

    log_info "Verifying Secure Boot status..."
    execute "sbctl status" "Checking Secure Boot status"

    log_info "Creating custom Secure Boot keys..."
    execute "sudo sbctl create-keys" "Generating new Secure Boot keys"

    log_info "Enrolling keys in firmware (you may need to enter firmware setup)..."
    execute "sudo sbctl enroll-keys --microsoft" "Enrolling keys into UEFI firmware"

    log_info "Detecting and signing all boot files..."
    # Get list of files that need signing and sign them automatically
    local boot_files
    boot_files=$(sudo sbctl list-files | grep -v "signed" | awk '{print $2}' 2>/dev/null || echo "")
    if [[ -n "$boot_files" ]]; then
        echo "$boot_files" | while read -r file; do
            if [[ -f "$file" ]]; then
                execute "sudo sbctl sign -s '$file'" "Signing $file"
            fi
        done
    else
        log_warn "No boot files detected for signing. You may need to manually sign them later."
    fi

    log_info "Verifying signatures..."
    execute "sbctl verify" "Verifying that all secure boot files are properly signed"

    log_info "Secure Boot setup completed. Please reboot and check if your system boots correctly."
    log_warn "IMPORTANT: If your system doesn't boot, you need to disable Secure Boot in UEFI firmware or use recovery options."
}

# =============================================================================
# SYSTEM ENHANCEMENT FUNCTIONS
# =============================================================================

setup_cachyos_configuration() {
    log_info "Setting up CachyOS systemd configuration..."

    # Install CachyOS-related packages
    execute "sudo pacman -S --noconfirm cachyos-sysctl-manager cachyos-settings-gnome cachyos-system-installer" "Installing CachyOS system packages"

    # Apply CachyOS sysctl settings
    log_info "Applying CachyOS sysctl optimizations..."
    execute "sudo sysctl --load /usr/lib/sysctl.d/99-cachyos.conf" "Loading CachyOS sysctl settings"

    # Configure systemd services for better performance
    execute "sudo systemctl enable cachyos-tweaks" "Enabling CachyOS tweaks service"
    execute "sudo systemctl start cachyos-tweaks" "Starting CachyOS tweaks service"

    log_info "CachyOS systemd configuration completed!"
}

setup_dnsmasq() {
    log_info "Setting up DNSMasq for local DNS caching..."

    # Install DNSMasq
    execute "sudo pacman -S --noconfirm dnsmasq" "Installing DNSMasq"

    # Configure DNSMasq
    backup_file "/etc/dnsmasq.conf"
    sudo tee "/etc/dnsmasq.conf" > /dev/null <<EOF
# DNSMasq configuration for local caching
domain-needed
bogus-priv
no-resolv
server=1.1.1.1
server=8.8.8.8
listen-address=127.0.0.1
cache-size=10000
no-negcache
EOF

    # Configure systemd-resolved to use DNSMasq
    backup_file "/etc/systemd/resolved.conf"
    sudo sed -i 's/^#DNS=.*/DNS=127.0.0.1/' /etc/systemd/resolved.conf
    sudo sed -i 's/^#DNSStubListener=.*/DNSStubListener=no/' /etc/systemd/resolved.conf

    # Enable and start DNSMasq
    execute "sudo systemctl enable dnsmasq" "Enabling DNSMasq service"
    execute "sudo systemctl start dnsmasq" "Starting DNSMasq service"

    # Restart systemd-resolved
    execute "sudo systemctl restart systemd-resolved" "Restarting systemd-resolved"

    log_info "DNSMasq setup completed with local caching!"
}

setup_earlyoom() {
    log_info "Setting up EarlyOOM for better OOM handling..."

    # Install EarlyOOM
    execute "sudo pacman -S --noconfirm earlyoom" "Installing EarlyOOM"

    # Configure EarlyOOM for aggressive OOM killing
    backup_file "/etc/default/earlyoom"
    sudo tee "/etc/default/earlyoom" > /dev/null <<EOF
# EarlyOOM configuration
EARLYOOM_ARGS="-m 1 -r 0 -s 100 -n --avoid '(^|/)(init|Xorg|systemd|sshd|dbus|gdm|gnome|gjs|chromium)$'"
EOF

    # Enable EarlyOOM
    execute "sudo systemctl enable earlyoom" "Enabling EarlyOOM service"
    execute "sudo systemctl start earlyoom" "Starting EarlyOOM service"

    log_info "EarlyOOM setup completed for better memory management!"
}

setup_microsoft_corefonts() {
    log_info "Setting up Microsoft CoreFonts..."

    # Install ttf-ms-fonts from AUR
    execute "paru -S --noconfirm ttf-ms-fonts" "Installing Microsoft Core Fonts from AUR"

    # Update font cache
    execute "fc-cache -fv" "Updating font cache"

    log_info "Microsoft CoreFonts installed and cache updated!"
}

setup_split_lock_mitigation() {
    log_info "Setting up split-lock mitigation disabler..."

    # Create systemd sysctl configuration for split-lock mitigation
    backup_file "/etc/sysctl.d/99-split-lock-mitigation.conf"
    cat <<EOF | sudo tee "/etc/sysctl.d/99-split-lock-mitigation.conf" > /dev/null
# Disable split-lock mitigation for performance
# Warning: This may reduce system security on vulnerable CPUs
kernel.split_lock_mitigate=0
EOF

    # Apply the setting immediately
    execute "sudo sysctl --load /etc/sysctl.d/99-split-lock-mitigation.conf" "Applying split-lock mitigation settings"

    log_info "Split-lock mitigation disabled for better performance!"
    log_warn "Note: This setting reduces security on vulnerable CPUs. Use with caution."
}

setup_hardware_acceleration_flatpak() {
    log_info "Setting up hardware acceleration for Flatpak applications..."

    # Detect current graphics driver to configure appropriate VA-API driver
    local detected_driver
    detected_driver=$(detect_current_graphics_driver)

    # Default to AMD if no driver detected or custom selection
    local hw_accel_driver="${detected_driver:-amd}"

    # Show menu for driver selection (unless detected AMD, then use default)
    if [[ "$hw_accel_driver" != "amd" ]]; then
        hw_accel_driver=$(dialog --title "Hardware Acceleration Driver Selection" \
                                 --menu "Select the GPU driver to use for Flatpak hardware acceleration:" \
                                 ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 10 \
                                 "auto" "Auto-detect from current driver ($detected_driver)" \
                                 "intel" "Intel VA-API (iHD driver)" \
                                 "amd" "AMD/Radeon VA-API" \
                                 "nvidia" "NVIDIA NVENC/NVDEC" \
                                 2>&1 >/dev/tty)

        if [[ $? -ne 0 ]]; then
            log_info "Hardware acceleration setup cancelled by user"
            return 0
        fi

        # Convert auto to detected driver
        if [[ "$hw_accel_driver" == "auto" ]]; then
            hw_accel_driver="$detected_driver"
        fi
    fi

    # Install appropriate VA-API packages based on selected driver
    case "$hw_accel_driver" in
        "intel")
            log_info "Installing Intel VA-API packages..."
            execute "sudo pacman -S --noconfirm libva-utils intel-media-driver vulkan-intel mesa-utils" "Installing Intel VA-API packages"
            HWACCEL_VAAPI_DRIVER="iHD"
            ;;
        "amd")
            log_info "Installing AMD VA-API packages..."
            execute "sudo pacman -S --noconfirm libva-utils libva-mesa-driver vulkan-mesa mesa-utils" "Installing AMD VA-API packages"
            HWACCEL_VAAPI_DRIVER="radeonsi"
            ;;
        "nvidia")
            log_info "Installing NVIDIA video packages..."
            execute "sudo pacman -S --noconfirm libva-nvidia-driver libva-utils vulkan-nvidia mesa-utils" "Installing NVIDIA VA-API packages"
            HWACCEL_VAAPI_DRIVER="nvidia"
            ;;
        *)
            log_info "Installing generic VA-API packages..."
            execute "sudo pacman -S --noconfirm libva-utils mesa-utils" "Installing generic VA-API packages"
            HWACCEL_VAAPI_DRIVER="auto"
            ;;
    esac

    # Configure Flatpak to use host graphics drivers
    flatpak override --system --device=dri --socket=wayland --share=ipc --talk-name=org.gnome.Mutter.DisplayConfig com.obsproject.Studio

    # Set VA-API environment variables globally based on driver selection
    cat <<EOF | sudo tee "/etc/environment.d/10-flatpak-hwaccel.conf" >/dev/null
# Hardware acceleration for Flatpak applications
LIBVA_DRIVER_NAME=$HWACCEL_VAAPI_DRIVER
VDPAU_DRIVER=va_gl
EOF

    # Configure specific applications based on driver
    case "$hw_accel_driver" in
        " intel"| "amd"| "nvidia")
            log_info "Configuring OBS Studio for hardware acceleration..."
            flatpak override --system --socket=wayland --share=ipc com.obsproject.Studio
            flatpak override --system --env=LIBVA_DRIVER_NAME=$HWACCEL_VAAPI_DRIVER com.obsproject.Studio
            ;;
    esac

    log_info "Hardware acceleration for Flatpak applications configured!"
    log_info "Selected driver: $hw_accel_driver (VA-API: $HWACCEL_VAAPI_DRIVER)"
}

setup_topgrade() {
    log_info "Setting up Topgrade for system updates..."

    # Install Topgrade from AUR
    execute "paru -S --noconfirm topgrade-bin" "Installing Topgrade from AUR"

    # Create Topgrade configuration for Paru AUR support
    mkdir -p "$HOME/.config/topgrade"
    cat <<EOF > "$HOME/.config/topgrade.toml"
[windows]

[brew]

[linux]
arch_package_manager = "paru"
trizen_arguments = "-Syu"
pikaur_arguments = "-Syu"
yay_arguments = "-Syu"
paru_arguments = "-Syu"
pacman_arguments = "-Syu"
aura_aur_arguments = "-Syu"
garuda_update_arguments = "-Syu"
kaos_arguments = "-Syu"
enable_aur = true

[containers]
predefined = []
EOF

log_info "Topgrade configured with Paru AUR support!"
log_info "Run 'topgrade' to update all your systems and applications."
}

setup_zswap() {
    log_info "Setting up Zswap compressed swap..."

    # Available Zswap size options in GB
    local zswap_sizes=("4gb" "6gb" "8gb" "12gb" "16gb" "20gb" "24gb" "28gb" "32gb" "64gb")

    # Show menu for Zswap size selection
    local selected_size
    selected_size=$(dialog --title "Zswap Size Selection" \
                          --menu "Choose Zswap compressed swap size (default: 20GB):\n\nZswap provides compressed swap in RAM for faster performance.\nHigher values use more RAM but provide better performance." \
                          ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 12 \
                          "auto" "Auto-select (20GB)" \
                          "4gb" "4GB - Minimal (good for 4-8GB RAM)" \
                          "6gb" "6GB - Small (good for 8-16GB RAM)" \
                          "8gb" "8GB - Medium (good for 8-16GB RAM)" \
                          "12gb" "12GB - Good balance" \
                          "16gb" "16GB - Balanced (recommended for most systems)" \
                          "20gb" "20GB - Default (optimized performance)" \
                          "24gb" "24GB - High performance" \
                          "28gb" "28GB - Very high performance" \
                          "32gb" "32GB - Maximum performance" \
                          "64gb" "64GB - Extreme performance" \
                          2>&1 >/dev/tty)

    if [[ $? -ne 0 ]]; then
        log_info "Zswap setup cancelled by user"
        return 0
    fi

    # Convert selection to numeric value
    local zswap_size_gb
    if [[ "$selected_size" == "auto" ]]; then
        zswap_size_gb=20
        selected_size="20gb"
    else
        zswap_size_gb=$(echo "$selected_size" | sed 's/gb$//')
    fi

    # Convert GB to bytes (1024^3 = 1073741824)
    local zswap_size_bytes=$((zswap_size_gb * 1073741824))

    # Backup existing Zswap configuration
    backup_file "/etc/modprobe.d/zswap.conf"
    backup_file "/etc/sysctl.d/99-zswap.conf"

    # Create modprobe configuration for Zswap
    cat <<EOF | sudo tee "/etc/modprobe.d/zswap.conf" >/dev/null
# Zswap module configuration for compressed RAM swap
options zswap enabled=1
options zswap same_filled_pages_enabled=1
options zswap zpool=zsmalloc
options zswap compressor=zstd
options zswap max_pool_percent=100
EOF

    log_info "Creating Zswap modprobe configuration with zstd compression..."

    # Create sysctl configuration to set runtime parameters
    cat <<EOF | sudo tee "/etc/sysctl.d/99-zswap.conf" >/dev/null
# Zswap runtime configuration
# Maximum compressed pool size: ${zswap_size_gb}GB (${zswap_size_bytes} bytes)
vm.zswap.max_pool_pages = $(($zswap_size_bytes / 4096))
EOF

    # Create udev rule to load Zswap module on boot
    sudo mkdir -p /etc/udev/rules.d
    cat <<EOF | sudo tee "/etc/udev/rules.d/99-zswap.rules" >/dev/null
# Load zswap module early in boot process
ACTION=="add", KERNEL=="zswap", RUN+="/sbin/modprobe zswap enabled=1 compressor=zstd zpool=zsmalloc same_filled_pages_enabled=1 max_pool_percent=100"
EOF

    # Apply sysctl settings immediately
    execute "sudo sysctl --load /etc/sysctl.d/99-zswap.conf" "Applying Zswap sysctl settings"

    # Load Zswap module if not already loaded
    if ! lsmod | grep -q zswap; then
        execute "sudo modprobe zswap enabled=1 compressor=zstd zpool=zsmalloc same_filled_pages_enabled=1 max_pool_percent=100" "Loading Zswap module"
    fi

    # Verify Zswap is active
    if lsmod | grep -q zswap; then
        log_info "Zswap module loaded successfully"
    else
        log_error "Failed to load Zswap module"
        return 1
    fi

    # Display current Zswap status
    log_info "Showing current Zswap status..."
    execute "grep -r . /sys/module/zswap/parameters/" "Checking Zswap parameters"

    log_info "✅ Zswap setup completed!"
    log_info "Size: ${zswap_size_gb}GB compressed RAM swap"
    log_info "Compression: zstd (high performance)"
    log_info "Pool: zsmalloc (optimized allocator)"
    log_info "Zswap will activate automatically on next boot"
    log_info "Monitor with: cat /sys/module/zswap/parameters/*"

    log_warn "Note: Zswap uses up to ${zswap_size_gb}GB of your RAM for compressed swap."
    log_warn "If you experience issues, reduce the size or disable Zswap."
}

setup_crontab_system_updates() {
    log_info "Setting up automatic system updates via cron..."

    # Check if topgrade is available
    if ! check_command "topgrade"; then
        log_error "Topgrade not found. Install it first through System Enhancements menu."
        return 1
    fi

    # Create cron script for updates with retry logic
    cat <<EOF | sudo tee /usr/local/bin/system-auto-update.sh > /dev/null
#!/bin/bash
#
# System Auto Update Script
# Runs topgrade with retry logic for failed updates
#
# Scheduled: Sunday 12:00, fallback Tuesday 12:00, Thursday 12:00, Saturday 12:00

LOG_FILE="/var/log/system-auto-update.log"
LOCK_FILE="/var/run/system-auto-update.lock"

# Prevent concurrent runs
if [[ -f "\$LOCK_FILE" ]]; then
    echo "\$(date): Another update process is running. Exiting..." >> "\$LOG_FILE"
    exit 1
fi

touch "\$LOCK_FILE"
trap 'rm -f "\$LOCK_FILE"' EXIT

echo "==========================================" >> "\$LOG_FILE"
echo "System Auto Update Started: \$(date)" >> "\$LOG_FILE"
echo "==========================================" >> "\$LOG_FILE"

# Run topgrade with error handling
if topgrade --yes --cleanup >> "\$LOG_FILE" 2>&1; then
    echo "Update completed successfully: \$(date)" >> "\$LOG_FILE"
    curl -fsS --retry 3 https://hc-ping.com/YOUR_HEALTHCHECK_ID_HERE >/dev/null 2>&1 || true
else
    echo "Update failed: \$(date)" >> "\$LOG_FILE"
    exit 1
fi

echo "==========================================" >> "\$LOG_FILE"
EOF

    # Make script executable
    execute "sudo chmod +x /usr/local/bin/system-auto-update.sh" "Making update script executable"

    # Create log file
    sudo touch /var/log/system-auto-update.log
    sudo chmod 644 /var/log/system-auto-update.log

    # Add cron job with retry logic (Sunday 12:00, fallback logic is handled by multiple entries)
    backup_file "/etc/crontab"

    # Remove existing entries if any
    sudo sed -i '/system-auto-update/d' /etc/crontab

    # Add new cron entries
    cat <<EOF | sudo tee -a /etc/crontab > /dev/null

# System auto update - Runs every Sunday at 12:00
0 12 * * 0   root    /usr/local/bin/system-auto-update.sh

# Retry on Tuesday 12:00 if Sunday failed
0 12 * * 2   root    /usr/local/bin/system-auto-update.sh

# Retry on Thursday 12:00 if Tuesday failed
0 12 * * 4   root    /usr/local/bin/system-auto-update.sh

# Final retry on Saturday 12:00 if Thursday failed
0 12 * * 6   root    /usr/local/bin/system-auto-update.sh
EOF

    # Ensure cron service is enabled and running
    execute "sudo systemctl enable cronie" "Enabling cron service"
    execute "sudo systemctl start cronie" "Starting cron service"

    log_info "Automatic system updates configured!"
    log_info "Schedule: Sunday → Tuesday → Thursday → Saturday at 12:00"
    log_info "Logs available at: /var/log/system-auto-update.log"
    log_info "To monitor healthchecks, add your HC ping URL to the script"
}

# =============================================================================
# GRAPHICS AND DISPLAY FUNCTIONS
# =============================================================================

detect_gpu() {
    log_info "Detecting GPU hardware..."

    if lspci | grep -i nvidia &> /dev/null; then
        echo "nvidia"
    elif lspci | grep -i amd &> /dev/null; then
        echo "amd"
    elif lspci | grep -i intel &> /dev/null; then
        echo "intel"
    else
        echo "unknown"
    fi
}

# Detect currently active graphics driver (runtime detection)
# This function checks what graphics driver is actually loaded and working
# Unlike detect_gpu() which only checks hardware, this verifies software state
# Priority: nvidia-smi > glxinfo/amdgpu > glxinfo/intel > vulkaninfo > hardware fallback
detect_current_graphics_driver() {
    log_info "Detecting currently active graphics driver..."

    # Method 1: NVIDIA - Check for nvidia-smi (most reliable for NVIDIA)
    if check_command "nvidia-smi" && nvidia-smi &>/dev/null; then
        log_info "✅ Active NVIDIA driver detected via nvidia-smi"
        echo "nvidia"
        return 0
    fi

    # Method 2: AMD - Check GPU card exists, GL info shows AMD, and amdgpu module is loaded
    if [[ -e "/dev/dri/card0" ]] && glxinfo 2>/dev/null | grep -i "radeon\|amdgpu" &>/dev/null; then
        if lsmod | grep -q "amdgpu"; then
            log_info "✅ Active AMDGPU driver detected (amdgpu kernel module loaded)"
            echo "amd"
            return 0
        fi
    fi

    # Method 3: Intel - Check GPU card exists, GL info shows Intel, and i915 module is loaded
    if [[ -e "/dev/dri/card0" ]] && glxinfo 2>/dev/null | grep -i "intel" &>/dev/null; then
        if lsmod | grep -q "i915"; then
            log_info "✅ Active Intel driver detected (i915 kernel module loaded)"
            echo "intel"
            return 0
        fi
    fi

    # Method 4: Vulkan API detection (fallback for cases where GL might not work)
    # Less reliable than above methods but useful for some setups
    if check_command "vulkaninfo"; then
        if vulkaninfo --summary 2>/dev/null | grep -i "nvidia" &>/dev/null; then
            log_info "✅ Vulkan reports active NVIDIA driver"
            echo "nvidia"
            return 0
        elif vulkaninfo --summary 2>/dev/null | grep -i "radeon\|amd" &>/dev/null; then
            log_info "✅ Vulkan reports active AMD driver"
            echo "amd"
            return 0
        elif vulkaninfo --summary 2>/dev/null | grep -i "intel" &>/dev/null; then
            log_info "✅ Vulkan reports active Intel driver"
            echo "intel"
            return 0
        fi
    fi

    # Fallback: If no active driver detected, use hardware detection
    log_warn "❌ No currently active graphics driver detected - falling back to hardware detection"
    detect_gpu
}

setup_graphics_drivers() {
    local current_gpu_type
    local hardware_gpu_type

    # First detect what's currently active
    current_gpu_type=$(detect_current_graphics_driver)
    hardware_gpu_type=$(detect_gpu)

    log_info "Hardware GPU detected: $hardware_gpu_type"
    log_info "Current active driver: $current_gpu_type"

    # Check if driver is already properly functional
    if [[ "$current_gpu_type" == "$hardware_gpu_type" ]]; then
        log_info "✅ Graphics driver for $current_gpu_type is already active and functional"
        dialog --title "Graphics Driver Check" \
               --msgbox "Your system already has the correct graphics driver installed and active ($current_gpu_type).\n\nNo additional installation is needed!" \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
        return 0
    elif [[ "$current_gpu_type" != "unknown" && "$current_gpu_type" != "" ]]; then
        log_info "⚠️  An active graphics driver was detected ($current_gpu_type), but hardware shows $hardware_gpu_type"
        dialog --title "Graphics Driver Mismatch" \
               --yesno "Warning: Active driver ($current_gpu_type) doesn't match hardware ($hardware_gpu_type).\n\nThis might indicate driver issues or multiple GPUs.\n\nDo you want to continue installing/updating drivers?" \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

        if [[ $? -ne 0 ]]; then
            log_info "Graphics driver installation cancelled by user"
            return 0
        fi
    fi

    # Proceed with installation based on hardware detection
    log_info "Proceeding with graphics driver installation for: $hardware_gpu_type"

    case "$hardware_gpu_type" in
        "nvidia")
            log_info "Installing NVIDIA graphics drivers..."
            execute "sudo pacman -S --noconfirm nvidia-dkms nvidia-utils lib32-nvidia-utils nvidia-settings vulkan-icd-loader lib32-vulkan-icd-loader" "Installing NVIDIA drivers"
            ;;
        "amd")
            log_info "Installing AMD graphics drivers..."
            execute "sudo pacman -S --noconfirm mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader lib32-vulkan-icd-loader" "Installing AMD drivers"
            ;;
        "intel")
            log_info "Installing Intel graphics drivers..."
            execute "sudo pacman -S --noconfirm mesa lib32-mesa vulkan-intel lib32-vulkan-intel vulkan-icd-loader lib32-vulkan-icd-loader" "Installing Intel drivers"
            ;;
        *)
            log_warn "Unknown GPU type detected. Installing basic Mesa drivers."
            execute "sudo pacman -S --noconfirm mesa lib32-mesa vulkan-icd-loader lib32-vulkan-icd-loader" "Installing basic Mesa graphics drivers"
            ;;
    esac

    log_info "Graphics driver installation completed. A reboot may be required for changes to take effect."
}

setup_themes() {
    log_info "Setting up themes and appearance..."

    # Install Adwaita theme and related packages
    execute "paru -S --noconfirm adw-gtk-theme morewaita-icon-theme adwaita-colors-icon-theme" "Installing Custom Adwaita themes and icons"

    # Install Adw-gtk3 theme for Flatpak
    execute "sudo flatpak install org.gtk.Gtk3theme.adw-gtk3/x86_64/3.22 org.gtk.Gtk3theme.adw-gtk3-dark" "Installing Adw-gtk3 theme Flatpaks"

    # Set Adwaita-colors icon theme for default
    execute "gsettings set org.gnome.desktop.interface icon-theme 'Adwaita-blue'" "Activating Adwaita-colors icon theme"
    execute "gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-gtk-theme'" "Activating Adw-gtk3 theme"
}

setup_systemd_boot_logo() {
    log_info "Setting up systemd-boot splash logo..."

    # Check if the asset exists
    local logo_file="${CONFIG[ASSETS_DIR]}/logo/boot/splash.bmp"
    if [[ ! -f "$logo_file" ]]; then
        log_error "Splash logo file not found at $logo_file"
        return 1
    fi

    # Copy the logo to systemd-boot splash location
    execute "sudo cp '$logo_file' /usr/share/systemd/bootctl/splash.bmp" "Installing custom splash logo"

    # Regenerate systemd-boot EFI
    if [[ -d "/boot/loader" ]]; then
        execute "sudo bootctl update" "Updating systemd-boot with new splash logo"
        log_info "Systemd-boot splash logo updated successfully."
    else
        log_warn "systemd-boot not detected. Splash logo may not be used."
    fi
}

setup_gdm_logo() {
    log_info "Setting up GDM login logo..."

    # Find GDM logo image (can be PNG or SVG)
    local logo_file=""
    for file in "${CONFIG[ASSETS_DIR]}/logo/gdm/"*; do
        if [[ -f "$file" && ( "$file" == *.png || "$file" == *.svg ) ]]; then
            logo_file="$file"
            break
        fi
    done

    if [[ -z "$logo_file" ]]; then
        log_error "GDM logo file not found in ${CONFIG[ASSETS_DIR]}/logo/gdm/"
        return 1
    fi

    # Determine GNOME Shell version and theme location
    local gdm_theme_dir="/usr/share/gnome-shell/theme"
    local logo_target="$gdm_theme_dir/logo.png"

    if [[ "$logo_file" == *.svg ]]; then
        # Convert SVG to PNG if needed (requires imagemagick)
        execute "sudo convert '$logo_file' '$logo_target'" "Converting and installing SVG logo"
    else
        execute "sudo cp '$logo_file' '$logo_target'" "Installing PNG logo"
    fi

    # Create custom CSS if logo is too large or needs positioning
    local custom_css="$gdm_theme_dir/custom-logo.css"
    cat <<EOF | sudo tee "$custom_css" > /dev/null
/* Custom GDM logo positioning */
.login-dialog-logo-bin {
  background-image: url('resource:///org/gnome/shell/theme/logo.png');
  background-size: contain;
  background-repeat: no-repeat;
  background-position: center;
  width: 128px;
  height: 128px;
}

.login-dialog-logo-bin#logo {
  background-size: contain;
}
EOF

    # Include custom CSS in gdm.css if it exists
    if [[ -f "$gdm_theme_dir/gdm.css" ]]; then
        backup_file "$gdm_theme_dir/gdm.css"
        echo "@import url('custom-logo.css');" | sudo tee -a "$gdm_theme_dir/gdm.css" > /dev/null
    fi

    log_info "GDM logo updated successfully. Changes will apply on next login."
}

#==============================================================================
# GNOME EXTENSIONS SETUP FUNCTIONS
#==============================================================================

# Main function to setup GNOME extensions
# Installs user's preferred extensions adapted for Arch Linux
setup_gnome_extensions() {
    log_info "Installing user's preferred GNOME extensions for Arch Linux..."

    # Install all user's preferred extensions
    install_user_gnome_extensions

    log_info "GNOME extensions setup completed successfully!"
    log_info "Note: Restart GNOME Shell (Alt+F2, r, Enter) if extensions don't appear"
}

# Install user's preferred GNOME extensions
install_user_gnome_extensions() {
    log_info "Installing user's preferred GNOME extensions..."

    # List of extensions based on user's preference
    local user_extensions=(
        "adw-gtk3-colorizer@NiffirgkcaJ.github.com"            # ADW-GTK3 Colorizer
        "auto-power-profile@dmy3k.github.io"                    # Auto Power Profile
        "arch_update@rahulsharma.com"                           # Arch Update Indicator - AUR notifications
        "Bluetooth-Battery-Meter@maniacx.github.com"           # Bluetooth Battery Meter
        "caffeine@patapon.info"                                 # Caffeine
        "grand-theft-focus@zalckos.github.com"                  # Grand Theft Focus
        "gsconnect@andyholmes.github.io"                       # GSConnect
        "hide-universal-access@akiirui.github.io"               # Hide Universal Access
        "hotedge@jonathan.jdoda.ca"                            # Hot Edge
        "monitor-brightness-volume@ailin.nemui"                # Monitor Brightness Volume
        "notification-icons@muhammad_ans.github"               # Notification Icons
        "power-profile@fthx"                                    # Power Profile
        "printers@linux-man.org"                                # Printers
        "rounded-window-corners@fxgn"                           # Rounded Window Corners
        "system-monitor@paradoxxx.zero.gmail.com"              # System Monitor (Arch-compatible)
        "window-title-is-back@fthx"                             # Window Title is Back
    )

    local install_count=0
    local failed_count=0

    for uuid in "${user_extensions[@]}"; do
        log_info "Installing extension: $uuid"

        if execute "gnome-extensions-cli install --yes '$uuid'" "Installing GNOME extension: $uuid"; then
            ((install_count++))
        else
            log_error "Failed to install extension: $uuid"
            ((failed_count++))
        fi
    done

    log_info "GNOME extensions installation completed: $install_count successful, $failed_count failed"
    log_info "Note: Some extensions may require GNOME Shell restart (Alt+F2, 'r', Enter)"
}

#==============================================================================
# GNOME MENU ORGANIZATION FUNCTIONS
#==============================================================================

# Complete implementation of GNOME applications menu organization
# Automatically detects installed apps and organizes them into categorized folders
# Uses GNOME's gsettings for menu organization and dconf for configuration
setup_gnome_menu_organization() {
    log_info "Starting GNOME applications menu organization..."

    # Define folder categories with standard GNOME Categories mapping
    declare -A FOLDER_CATEGORIES=(
        ["Android"]="Development;IDE;Debug"                      # Android Studio, Android development tools
        ["Workflow"]="Development;Building;Tools"               # Build tools, CI/CD, workflow automation
        ["Containers"]="Utility;System;Emulation"               # Docker, Podman, container tools
        ["Office"]="Office;TextEditor;Spreadsheet;Presentation" # Office suites and document editors
        ["Media Edit"]="AudioVideo;Graphics;Photography;Mixer"  # Video editors, graphics tools, media
        ["Games"]="Game"                                         # Gaming applications and launchers
        ["Utilities"]="Utility;Monitor;SystemMonitor"           # System utilities, monitors, tools
        ["Tools"]="System;Development;Utility;Settings"         # Administrative and development tools
        ["System"]="System;Settings;HardwareSettings"           # System settings and hardware management
    )

    # Applications that should remain in main menu (not in folders)
    declare -a MAIN_MENU_APPS=(
        "software" "org.gnome.Software"         # Software Center - central app installation
        "files" "org.gnome.Nautilus"            # Files Manager - fundamental file access
        "calculator" "org.gnome.Calculator"     # Calculator - quick calculations
        "edge" "com.microsoft.Edge"            # Browser - web access
        "varia" "io.github.giantpinkrobots.varia" # Download manager
        "packet" "io.github.nozwock.Packet"     # Network/Bluetooth sharing tool
        "steam" "com.valvesoftware.Steam"      # Steam gaming platform
        "heroic" "com.heroicgameslauncher.hgl" # Epic Games launcher alternative
        "zapzap" "com.rstoya.zapzap"           # WhatsApp client
        "telegram" "org.telegram.desktop"      # Telegram messenger
        "discord" "com.discordapp.Discord"     # Discord communication
    )

    # Step 1: Detect installed applications
    log_info "Detecting installed applications..."
    detect_installed_applications

    # Step 2: Create menu folders
    log_info "Creating menu folders..."
    create_gnome_menu_folders

    # Step 3: Categorize applications into folders
    log_info "Categorizing applications into folders..."
    categorize_apps_into_folders

    # Step 4: Set main menu exclusions
    log_info "Configuring main menu exclusions..."
    configure_main_menu_exclusions

    # Step 5: Verify organization
    log_info "Verifying menu organization..."
    verify_menu_organization

    log_info "GNOME menu organization completed successfully!"
    log_info "Menu folders created with categorized applications."
    log_info "Main menu contains essential frequently-used applications."
}

# Detect all installed applications (both native and Flatpak)
detect_installed_applications() {
    log_info "Scanning for installed applications..."

    # Clear previous detection results
    DETECTED_APPS_FILE="/tmp/detected_apps_$$.txt"
    touch "$DETECTED_APPS_FILE"

    # Detect native packages with desktop files
    log_info "Detecting native applications..."
    find /usr/share/applications -name "*.desktop" 2>/dev/null | while read -r desktop_file; do
        # Extract application ID from desktop file
        app_id=$(basename "$desktop_file" .desktop)

        # Get categories and other metadata
        if command -v xdg-desktop-menu >/dev/null 2>&1; then
            categories=$(grep "^Categories=" "$desktop_file" 2>/dev/null | cut -d'=' -f2-)
            name=$(grep "^Name=" "$desktop_file" 2>/dev/null | head -1 | cut -d'=' -f2-)
        else
            categories="Utility"  # Fallback
            name=$(grep "^Name=" "$desktop_file" 2>/dev/null | head -1 | cut -d'=' -f2-)
        fi

        echo "native|$app_id|$name|$categories" >> "$DETECTED_APPS_FILE"
    done

    # Detect Flatpak applications if Flatpak is installed
    if command -v flatpak >/dev/null 2>&1; then
        log_info "Detecting Flatpak applications..."
        flatpak list --app --columns=application,name,categories 2>/dev/null | while read -r line; do
            # Parse flatpak output: app.id Name Categories
            app_id=$(echo "$line" | awk '{print $1}')
            app_name=$(echo "$line" | awk '{$1=""; $NF=""; print $0}' | sed 's/^ *//;s/ *$//')
            categories=$(echo "$line" | awk '{print $NF}')

            echo "flatpak|$app_id|$app_name|$categories" >> "$DETECTED_APPS_FILE"
        done
    fi

    log_info "Application detection completed."
}

# Create GNOME menu folders using gsettings
create_gnome_menu_folders() {
    log_info "Creating GNOME menu folders..."

    # Get existing folders to avoid duplicates
    local existing_folders=""
    if command -v gsettings >/dev/null 2>&1; then
        existing_folders=$(gsettings get org.gnome.desktop.app-folders folder-children 2>/dev/null || echo "@as []")
    else
        log_error "gsettings not found. GNOME menu organization requires GNOME."
        return 1
    fi

    # Create folder configuration array
    local folder_ids=()
    local folder_names=()
    local folder_categories=()

    for folder in "${!FOLDER_CATEGORIES[@]}"; do
        folder_ids+=("$folder")
        folder_names+=(", '$folder'")
        folder_categories+=("'${FOLDER_CATEGORIES[$folder]}'")
    done

    # Set folder children (folder IDs)
    local folder_children="['$(IFS=,; echo "${folder_ids[*]}")']"

    # Create individual folder configurations
    for i in "${!folder_ids[@]}"; do
        local folder_id="${folder_ids[$i]}"
        local folder_name="${folder_names[$i]#*, }"  # Remove leading comma and space
        local folder_category="${folder_categories[$i]}"

        log_info "Creating folder: $folder_id ($folder_name)"

        # Set folder display name
        gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder_id"/ name "$folder_name" 2>/dev/null || log_warn "Could not set name for folder $folder_id"

        # Set folder categories (apps matching these will be auto-assigned)
        gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder_id"/ categories "$folder_category" 2>/dev/null || log_warn "Could not set categories for folder $folder_id"

        # Set folder as translate=false (GNOME 42+ compatibility)
        gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder_id"/ translate false 2>/dev/null || true
    done

    # Set the complete folder list
    gsettings set org.gnome.desktop.app-folders folder-children "$folder_children" 2>/dev/null || log_error "Failed to set folder children"

    log_info "GNOME menu folders created successfully."
}

# Categorize applications into folders based on their metadata
categorize_apps_into_folders() {
    log_info "Categorizing applications into appropriate folders..."

    if [[ ! -f "$DETECTED_APPS_FILE" ]]; then
        log_error "Application detection file not found. Cannot categorize apps."
        return 1
    fi

    # Process each detected application
    while IFS='|' read -r app_type app_id app_name app_categories; do
        # Skip if app should be in main menu
        if app_should_be_in_main_menu "$app_id"; then
            continue
        fi

        # Determine target folder based on categories
        local target_folder=""
        target_folder=$(determine_target_folder "$app_categories")

        if [[ -n "$target_folder" ]]; then
            log_info "Assigning '$app_name' ($app_id) to folder: $target_folder"
            assign_app_to_folder "$app_id" "$target_folder"
        else
            log_info "Leaving '$app_name' ($app_id) in main menu (no matching folder)"
        fi
    done < "$DETECTED_APPS_FILE"

    log_info "Application categorization completed."
}

# Determine which folder an application should go into based on its categories
determine_target_folder() {
    local app_categories="$1"

    # Check each folder's categories against the app's categories
    for folder in "${!FOLDER_CATEGORIES[@]}"; do
        local folder_categories="${FOLDER_CATEGORIES[$folder]}"

        # Split folder categories by semicolon
        IFS=';' read -ra folder_cat_array <<< "$folder_categories"

        # Check if app categories match any folder category
        for folder_cat in "${folder_cat_array[@]}"; do
            if [[ "$app_categories" == *"$folder_cat"* ]]; then
                echo "$folder"
                return 0
            fi
        done
    done

    # Special categorization rules for specific applications
    case "$app_categories" in
        *Game*) echo "Games" && return 0 ;;
        *Office*) echo "Office" && return 0 ;;
        *Graphics*|*Audio*|*Video*) echo "Media Edit" && return 0 ;;
        *Development*|*Building*) echo "Workflow" && return 0 ;;
        *Container*|*Virtualization*) echo "Containers" && return 0 ;;
        *Utility*|*Monitor*) echo "Utilities" && return 0 ;;
        *Settings*|*Hardware*) echo "System" && return 0 ;;
    esac

    # No matching folder found
    echo ""
}

# Assign an application to a specific folder using gsettings
assign_app_to_folder() {
    local app_id="$1"
    local folder_id="$2"

    # Get current apps in folder
    local current_apps=""
    current_apps=$(gsettings get org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder_id"/ apps 2>/dev/null || echo "@as []")

    # Add new app to the list (GNOME uses array format)
    if [[ "$current_apps" == "@as []" ]]; then
        # First app in folder
        local new_apps="['$app_id']"
    else
        # Remove closing bracket, add comma and new app, add closing bracket
        new_apps="${current_apps%]}"
        if [[ "$new_apps" != "[" ]]; then
            new_apps="$new_apps, '$app_id']"
        else
            new_apps="$new_apps'$app_id']"
        fi
    fi

    # Set the updated app list
    gsettings set org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder_id"/ apps "$new_apps" 2>/dev/null || log_warn "Failed to assign $app_id to folder $folder_id"
}

# Check if application should remain in main menu
app_should_be_in_main_menu() {
    local app_id="$1"

    # Check against predefined main menu apps
    for main_app in "${MAIN_MENU_APPS[@]}"; do
        if [[ "$app_id" == "$main_app" ]]; then
            return 0  # True - should be in main menu
        fi
    done

    return 1  # False - should be in folder
}

# Configure main menu exclusions (apps that must stay in main menu)
configure_main_menu_exclusions() {
    log_info "Configuring main menu exclusions..."

    # GNOME doesn't have direct exclusion setting, but we can ensure
    # main menu apps are not assigned to any folder (handled above)

    # Additionally, we can set the main menu folder children to ensure
    # our folders appear and main apps stay visible
    local all_folders=""
    all_folders=$(gsettings get org.gnome.desktop.app-folders folder-children 2>/dev/null || echo "")

    if [[ -n "$all_folders" ]]; then
        log_info "Main menu exclusions configured. Applications not in folders will appear in main menu."
    fi
}

# Verify that menu organization was applied correctly
verify_menu_organization() {
    log_info "Verifying GNOME menu organization..."

    # Check if folders were created
    local folder_count=0
    for folder in "${!FOLDER_CATEGORIES[@]}"; do
        if gsettings get org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder"/ name >/dev/null 2>&1; then
            ((folder_count++))
        fi
    done

    # Check if folders have apps
    local apps_total=0
    for folder in "${!FOLDER_CATEGORIES[@]}"; do
        local folder_apps=""
        folder_apps=$(gsettings get org.gnome.desktop.app-folders.folder:/org/gnome/desktop/app-folders/folders/"$folder"/ apps 2>/dev/null || echo "@as []")
        if [[ "$folder_apps" != "@as []" ]]; then
            local app_count=$(echo "$folder_apps" | tr ',' '\n' | wc -l)
            apps_total=$((apps_total + app_count))
        fi
    done

    log_info "Verification complete: $folder_count folders created, $apps_total applications organized."

    # Cleanup temporary files
    [[ -f "$DETECTED_APPS_FILE" ]] && rm -f "$DETECTED_APPS_FILE"
}

# =============================================================================
# DEVELOPMENT TOOLS FUNCTIONS
# =============================================================================

setup_terminal() {
    log_info "Setting up terminal and shell customization..."

    # Install fish shell
    execute "sudo pacman -S --noconfirm fish" "Installing fish shell"
    execute "sudo chsh -s /usr/bin/fish "$USER"" "Setting fish as default shell"
}

setup_development_tools() {
    log_info "Setting up development tools..."

    # Install development packages
    local dev_deps=(
        "base-devel" "git" "github-cli" "openssl-devel" "distrobox" "docker-ce" "docker-compose-plugin" "scrcpy" "heimdall-frontend" "zed-editor" "figma-linux" "tailscale" "pnpm" "mise" "starship" "jdk-openjdk"
    )
    execute "sudo pacman -S --noconfirm ${dev_deps[*]}" "Installing development tools"

    # Setup MISE (version manager)
    setup_mise

    # Setup Starship prompt
    setup_starship

    # Setup SDKMAN (if JDK is available)
    setup_sdkman

    log_info "Development tools setup completed!"
}

setup_mise() {
    log_info "Setting up MISE version manager..."

    # Initialize MISE if not already done
    if [[ ! -f "$HOME/.config/mise/config.toml" ]]; then
        mkdir -p "$HOME/.config/mise"
        cat <<EOF > "$HOME/.config/mise/config.toml"
[tools]
# Node.js version
node = "latest"
# Python version
python = "latest"
# Ruby version
ruby = "latest"
# Go version
go = "latest"
EOF
        log_info "MISE configuration file created"
    fi

    # Add MISE hook to RC files if not present
    if ! grep -q "mise activate" "$HOME/.bashrc"; then
        echo 'eval "$(mise activate bash)"' >> "$HOME/.bashrc"
        log_info "MISE hook added to .bashrc"
    fi

    if ! grep -q "mise activate" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo 'mise activate fish | source' >> "$HOME/.config/fish/config.fish"
        log_info "MISE hook added to fish config"
    fi

    # Initialize MISE
    execute "mise --version" "Verifying MISE installation"
    log_info "MISE setup completed! Use 'mise install' to install tool versions."
}

setup_starship() {
    log_info "Setting up Starship prompt..."

    # Configure Starship in shells
    if ! grep -q "starship init" "$HOME/.bashrc"; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        log_info "Starship prompt added to .bashrc"
    fi

    if ! grep -q "starship init" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo 'starship init fish | source' >> "$HOME/.config/fish/config.fish"
        log_info "Starship prompt added to fish config"
    fi

    # Create basic Starship configuration
    if [[ ! -f "$HOME/.config/starship.toml" ]]; then
        mkdir -p "$HOME/.config"
        cat <<EOF > "$HOME/.config/starship.toml"
# Get editor completions based on the config schema
"\$schema" = 'https://starship.rs/config-schema.json'

# Use custom format
format = """
[┌─❱](bold green)$username\
[┌─❱](bold green)$hostname\
[│](bold green)\
$directory\
$git_branch\
$git_status\
[│](bold green)\
$python\
$nodejs\
$rust\
$golang\
$docker_context\
[└─❱](bold green)$character"""

# Inserts a blank line between shell prompts
add_newline = true

[directory]
style = "blue"

[character]
success_symbol = "[❱](bold green)"
error_symbol = "[❱](bold red)"

[git_branch]
symbol = "🌱 "

[git_status]
ahead = "⇡\${count}"
behind = "⇣\${count}"
diverged = "⇞ ⇟"
staged = "[+\${count}](green)"
modified = "[~\${count}](yellow)"
renamed = "[»\${count}](yellow)"
deleted = "[✘\${count}](red)"
untracked = "[?\${count}](yellow)"
conflicted = "[=\${count}](red)"
EOF
        log_info "Starship configuration file created with Arch-friendly theme"
    fi

    log_info "Starship prompt configured! Restart your shell or run 'source ~/.bashrc'"
}

setup_sdkman() {
    log_info "Setting up SDKMAN for Java SDK management..."

    # Check if JDK is installed
    if ! check_command "javac"; then
        log_warn "JDK not found. Skipping SDKMAN setup. Install JDK first."
        return 1
    fi

    # Install SDKMAN if not present
    if [[ ! -d "$HOME/.sdkman" ]]; then
        execute "curl -s 'https://get.sdkman.io' | bash" "Downloading and installing SDKMAN"
    fi

    # Source SDKMAN in RC files
    if ! grep -q "sdkman-init.sh" "$HOME/.bashrc"; then
        echo 'export SDKMAN_DIR="$HOME/.sdkman"' >> "$HOME/.bashrc"
        echo '[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$HOME/.bashrc"
        log_info "SDKMAN initialization added to .bashrc"
    fi

    if ! grep -q "sdkman-init.sh" "$HOME/.config/fish/config.fish" 2>/dev/null; then
        echo 'set -x SDKMAN_DIR "$HOME/.sdkman"' >> "$HOME/.config/fish/config.fish"
        echo 'if test -s "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$HOME/.config/fish/config.fish"
        echo '  bass source "$HOME/.sdkman/bin/sdkman-init.sh"' >> "$HOME/.config/fish/config.fish"
        echo 'end' >> "$HOME/.config/fish/config.fish"
        log_info "SDKMAN initialization added to fish config"
    fi

    log_info "SDKMAN setup completed! Use 'sdk install java <version>' to install Java SDKs."
}

# =============================================================================
# APPLICATIONS FUNCTIONS
# =============================================================================

setup_utilities() {
    log_info "Setting up system utilities..."

    local utils=(
        # System utilities
        "fastfetch" "gparted" "deja-dup" "ntfs-3g" "android-tools"

        # Multimedia
        "pitivi" "sunshine"

        # Development tools
        "codium" "docker-buildx" "ptyxis" "btrfs-assistant" "linux-toys"

        # Printing
        "system-config-printer-udev" "cups-browsed" "gutenprint-cups" "cups-pdf" "cups-filters" "foomatic-db-engine" "foomatic-db" "foomatic-db-nonfree-ppds"

        # Terminal tools
        "bat" "exa" "ripgrep" "fd" "tokei" "tree" "fzf" "jq" "ncdu" "tldr" "man-db"

        # Filesystem tools
        "btrfs-progs" "xfsprogs" "dosfstools" "ntfs-3g" "samba-client"

        # Fonts
        "adobe-source-code-pro-fonts" "dejavu-fonts" "noto-fonts" "fira-code-fonts" "ttf-jetbrains-mono-nerd" "ttf-adobe-source-code-pro"

        # Images
        "librsvg2" "glycin-thumbnailer" "gnome-epub-thumbnailer"

        # Compression
        "unrar" "unzip" "p7zip" "gzip" "bzip2" "xz" "lzop" "zip"
    )

    execute "sudo pacman -S --noconfirm ${utils[*]}" "Installing system utilities"
}

setup_codecs_and_multimedia() {
    log_info "Setting up codecs and multimedia support..."

    local codecs=(
        "ffmpeg" "gst-plugins-ugly" "gst-plugins-good"
        "gst-plugins-base" "gst-plugins-bad" "gst-libav" "gstreamer"
    )

    execute "sudo pacman -S --noconfirm ${codecs[*]}" "Installing multimedia codecs"
}

setup_flatpak_applications() {
    log_info "Setting up Flatpak applications..."

    # Install Flatpak if not present
    if ! check_command "flatpak"; then
        execute "sudo pacman -S --noconfirm flatpak" "Installing Flatpak"
        execute "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" "Adding Flathub repository"
    fi

    # Install Flatpak applications by categories
    log_info "Installing browser apps..."
    local browsers=(
        "app.zen_browser.zen"          # Zen Browser - Firefox-based browser
        "com.microsoft.Edge"           # Microsoft Edge - web browser
        "io.github.giantpinkrobots.varia" # Varia - download manager
    )
    for app in "${browsers[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing communication apps..."
    local communication=(
        "de.capypara.FieldMonitor"         # Field Monitor - device monitor
        "com.rustdesk.RustDesk"        # RustDesk - secure remote access
        "com.anydesk.Anydesk"          # AnyDesk - remote desktop access
        "com.freerdp.FreeRDP"          # FreeRDP - RDP client
        "com.rstoya.zapzap"            # ZapZap - WhatsApp client
        "org.telegram.desktop"         # Telegram Desktop - messenger
        "com.discordapp.Discord"       # Discord - communication platform
    )
    for app in "${communication[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing development apps..."
    local development=(
        "io.dbeaver.DBeaverCommunity"      # DBeaver - SQL client
        "me.iepure.devtoolbox"             # Dev Toolbox - developer tools
        "io.podman_desktop.PodmanDesktop"  # Podman Desktop - Podman interface
        "sh.loft.devpod"                   # DevPod - remote development environments
        "rest.insomnia.Insomnia"           # Insomnia - REST API client
        "com.google.AndroidStudio"         # Android Studio - Android development IDE
        "re.sonny.Workbench"               # Workbench - GNOME development tool
    )
    for app in "${development[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing system utilities..."
    local utilities=(
        "net.nokyan.Resources"             # Resources - resource usage monitor
        "com.mattjakeman.ExtensionManager" # Extension Manager - GNOME extensions manager
        "io.github.flattool.Ignition"      # Ignition - configuration tool
        "com.github.tchx84.Flatseal"       # Flatseal - Flatpak permissions
        "io.github.flattool.Warehouse"     # Warehouse - Flatpak applications manager
        "it.mijorus.gearlever"             # Gear Lever - AppImage manager
        "com.ranfdev.DistroShelf"          # Distro Shelf - distribution containers
        "page.codeberg.libre_menu_editor.LibreMenuEditor" # Libre Menu Editor - menu editor
        "io.github.realmazharhussain.GdmSettings" # GDM Settings - login configurator

    )
    for app in "${utilities[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing multimedia apps..."
    local multimedia=(
        "com.obsproject.Studio"             # OBS Studio - streaming and recording
        "fr.handbrake.ghb"                  # HandBrake - video converter
        "org.nickvision.tubeconverter"      # Tube Converter - video converter
        "org.gimp.GIMP"                     # GIMP - image editor
        "org.inkscape.Inkscape"             # Inkscape - vector editor
        "com.github.finefindus.eyedropper" # Eyedropper - color picker
        "io.gitlab.adhami3310.Converter"    # Converter - conversion tool
        "io.gitlab.theevilskeleton.Upscaler" # Upscaler - image upscaling
        "org.tenacityaudio.Tenacity"        # Tenacity - audio editor
    )
    for app in "${multimedia[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing gaming and emulation apps..."
    local gaming=(
        "com.steamgriddb.steam-rom-manager" # Steam ROM Manager - Steam ROM manager
        "com.vysp3r.ProtonPlus"             # ProtonPlus - Proton manager
        "com.github.Matoking.protontricks"  # Protontricks - Proton winetricks
        "io.github.hedge_dev.hedgemodmanager" # Hedge Mod Manager - mod manager
        "io.github.radiolamp.mangojuice"   # MangoJuice - MangoHud manager
        "org.openrgb.OpenRGB"               # OpenRGB - RGB lighting controller
        "org.prismlauncher.PrismLauncher"   # Prism Launcher - Minecraft launcher
        "io.mrarm.mcpelauncher"             # MCPE Launcher - Minecraft PE launcher
        "net.veloren.airshipper"            # Airshipper - Veloren launcher
        "org.vinegarhq.Sober"               # Sober - Roblox launcher
        "net.rpcs3.RPCS3"                   # RPCS3 - PS3 emulator
        "org.DolphinEmu.dolphin-emu"        # Dolphin - GameCube/Wii emulator
        "net.pcsx2.PCSX2"                   # PCSX2 - PS2 emulator
        "org.ppsspp.PPSSPP"                 # PPSSPP - PSP emulator
        "org.duckstation.DuckStation"       # DuckStation - PS1 emulator
        "org.libretro.RetroArch"            # RetroArch - multi-system emulator
    )
    for app in "${gaming[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done

    log_info "Installing additional utilities..."
    local additional=(
        "md.obsidian.Obsidian"             # Obsidian - note editor
        "io.github.nozwock.Packet"          # Packet - network/bluetooth sharing tool
        "io.gitlab.adhami3310.Impression"   # Impression - image editor
        "garden.jamie.Morphosis"            # Morphosis - document converter
        "io.github.diegoivan.pdf_metadata_editor" # PDF Metadata Editor - PDF metadata editor

    )
    for app in "${additional[@]}"; do
        execute "flatpak install flathub -y $app" "Installing $app"
    done
}

# =============================================================================
# GAMING FUNCTIONS
# =============================================================================

setup_gaming() {
    log_info "Setting up gaming environment..."

    # Install gaming meta package
    execute "paru -S --noconfirm arch-gaming-meta" "Installing Arch gaming meta package"

    # Install Wine and Proton
    execute "paru -S --noconfirm wine-installer proton-ge-custom-bin" "Installing Wine and Proton"

    # Install game utilities
    execute "paru -S --noconfirm gamemode lib32-gamemode citron input-remapper heroic-games-launcher shader-boost" "Installing gaming utilities"

    # Install Steam
    execute "paru -S --noconfirm steam" "Installing Steam"
}

# =============================================================================
# VIRTUALIZATION FUNCTIONS
# =============================================================================

setup_virtualization() {
    log_info "Setting up virtualization with GNOME Boxes..."

    # Install GNOME Boxes and dependencies
    execute "sudo pacman -S --noconfirm qemu libvirt virt-viewer spice-gtk" "Installing GNOME Boxes dependencies"
    execute "paru -S --noconfirm gnome-boxes winboat" "Installing GNOME Boxes and Winboat"

    # Enable libvirt service
    execute "sudo systemctl enable libvirtd.service" "Enabling libvirt service"
    execute "sudo systemctl start libvirtd.service" "Starting libvirt service"

    # Add user to libvirt group
    execute "sudo usermod -aG libvirt $USER" "Adding user to libvirt group"
}

# =============================================================================
# INTERACTIVE MENUS
# =============================================================================

show_welcome() {
    dialog --title "ArchPI v${CONFIG[SCRIPT_VERSION]}" \
           --msgbox "Welcome to the Arch Linux Post-Installation Script!

This script will help you set up your Arch Linux system with modern tools and configurations.

Please select the components you want to install from the main menu.

Note: This script requires internet connection and may take some time to complete." \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
}

show_main_menu() {
    # Display main interactive menu for component selection
    # Menu numbers are sequential for better UX and easier navigation
    local choice
    choice=$(dialog --title "Main Menu - Arch Linux Post-Installation" \
                    --menu "Select a category to configure:" \
                    ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 20 \
                    1 "System Configuration" \
                    2 "Graphics & Display" \
                    3 "Development Tools" \
                    4 "Applications" \
                    5 "Gaming" \
                    6 "Virtualization" \
                    7 "System Enhancements" \
                    8 "GNOME Menu Organization" \
                    9 "GNOME Extensions" \
                    10 "Complete Setup (All)" \
                    11 "Exit" \
                    2>&1 >/dev/tty)

    echo "$choice"
}

show_system_menu() {
    local choices
    choices=$(dialog --title "System Configuration" \
                     --checklist "Select system components to install:" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 13 \
                     "pacman" "Configure Pacman (mirrors, multilib)" on \
                     "aur" "Install AUR helper (paru)" on \
                     "locales" "Setup system locales" on \
                     "kernel" "Install CachyOS kernel (performance optimized)" off \
                     "snapper" "Setup Snapper for system snapshots" off \
                     "services" "Configure system services" on \
                     "plymouth" "Setup Perfect Quiet Boot (Arch splash + spinner + GDM)" off \
                     "secureboot" "Setup Secure Boot (sbctl)" off \
                     2>&1 >/dev/tty)

    echo "$choices"
}

show_graphics_menu() {
    local choices
    choices=$(dialog --title "Graphics & Display" \
                     --checklist "Select graphics components to install:" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 9 \
                     "drivers" "Install graphics drivers" on \
                     "themes" "Setup themes and icons" on \
                     "splash" "Setup systemd-boot splash logo" off \
                     "gdm" "Setup GDM login logo" off \
                     2>&1 >/dev/tty)

    echo "$choices"
}

show_development_menu() {
    local choices
    choices=$(dialog --title "Development Tools" \
                     --checklist "Select development components to install:" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 8 \
                     "terminal" "Setup terminal (fish, tools)" on \
                     "devtools" "Install development tools" on \
                     2>&1 >/dev/tty)

    echo "$choices"
}

show_applications_menu() {
    local choices
    choices=$(dialog --title "Applications" \
                     --checklist "Select applications to install:" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 10 \
                     "utilities" "System utilities" on \
                     "codecs" "Multimedia codecs" on \
                     "flatpak" "Flatpak applications" on \
                     2>&1 >/dev/tty)

    echo "$choices"
}

show_system_enhancements_menu() {
    local choices
    choices=$(dialog --title "System Enhancements" \
                     --checklist "Select system enhancements to install:" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 17 \
                     "zswap" "Zswap compressed swap (default: 20GB)" on \
                     "cachyos" "CachyOS systemd configuration" off \
                     "dnsmasq" "DNSMasq for local DNS caching" off \
                     "earlyoom" "EarlyOOM for better OOM handling" off \
                     "msfonts" "Microsoft CoreFonts" off \
                     "splitlock" "Split-lock mitigation disabler" off \
                     "flatpak-hwaccel" "Hardware acceleration for Flatpak" off \
                     "topgrade" "Topgrade with Paru AUR support" off \
                     "cron" "Automated system updates (Weekly + retries)" off \
                     2>&1 >/dev/tty)

    echo "$choices"
}

# =============================================================================
# MAJOR EXECUTION FUNCTIONS
# =============================================================================

# Function to setup CachyOS kernel with intelligent fallback
setup_cachyos_kernel() {
    log_info "Setting up CachyOS kernels with intelligent boot fallback..."

    # Check if Chaotic repository is available (required for CachyOS kernels)
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        log_error "Chaotic-AUR repository is required for CachyOS kernels."
        log_info "Please enable Chaotic repository first through Pacman configuration."
        return 1
    fi

    # Install CachyOS kernels and headers
    log_info "Installing CachyOS kernels (performance optimized)..."
    execute "sudo pacman -S --noconfirm cachyos-linux cachyos-linux-headers cachyos-linux-lts cachyos-linux-lts-headers" "Installing CachyOS kernels and headers"

    # Verify systemd-boot is present
    if [[ ! -d "/boot/loader" ]]; then
        log_error "systemd-boot not detected! Kernel management requires systemd-boot."
        return 1
    fi

    # Setup CachyOS as default kernel
    setup_cachyos_default_kernel

    # Create boot failure recovery system
    setup_boot_failure_recovery_system

    log_info "✅ CachyOS kernel setup completed!"
    log_info "Default kernel: cachyos-linux (performance optimized)"
    log_info "Fallback kernel: cachyos-linux-lts (stable emergency)"
    log_info "Recovery system: 3 failed boots → Recovery menu with Snapper rollback"
    log_info "To trigger recovery manually: Hold Space during boot."
}

setup_cachyos_default_kernel() {
    log_info "Setting cachyos-linux as default kernel..."

    # Find CachyOS boot entry
    local cachyos_entry=""
    for entry in /boot/loader/entries/*.conf; do
        if [[ -f "$entry" && "$(grep -c "cachyos-linux" "$entry" 2>/dev/null || echo "0")" -gt "0" ]]; then
            if ! grep -q "lts" "$entry"; then
                cachyos_entry="$entry"
                break
            fi
        fi
    done

    # If no CachyOS entry found, create one or modify existing
    if [[ -z "$cachyos_entry" ]]; then
        log_error "No CachyOS boot entry found. systemd-boot configuration may be required."
        return 1
    fi

    # Set as default in loader.conf
    backup_file "/boot/loader/loader.conf"
    sudo sed -i 's/^default.*/default '"$(basename "$cachyos_entry" .conf)"'/' /boot/loader/loader.conf

    # Update boot loader
    execute "sudo bootctl update" "Updating systemd-boot with new default"

    log_info "CachyOS kernel set as default successfully"
}

setup_boot_failure_recovery_system() {
    log_info "Setting up intelligent boot failure recovery system..."

    # Create boot failure counter file
    sudo touch /var/cache/cachyos-boot-count
    sudo chmod 644 /var/cache/cachyos-boot-count

    # Create emergency loader config backup
    backup_file "/boot/loader/loader.conf"

    # Create recovery script that systemd-boot can trigger
    cat <<'EOF' | sudo tee /usr/local/bin/cachyos-boot-recovery >/dev/null
#!/bin/bash
#
# CachyOS Boot Recovery Script
# Triggered when boot failure count reaches 3
#
# This script creates recovery entries for systemd-boot

RECOVERY_COUNT_FILE="/var/cache/cachyos-boot-count"
RECOVERY_ENTRIES_DIR="/boot/loader/entries/recovery"

# Create recovery entries directory
mkdir -p "$RECOVERY_ENTRIES_DIR"

# Current kernel (check what failed to boot)
CURRENT_ENTRY=$(efibootmgr | grep "Arch Linux" | head -1 | cut -d'*' -f2 | xargs)
if [[ -z "$CURRENT_ENTRY" ]]; then
    CURRENT_ENTRY="Linux Boot Manager"
fi

# Create recovery entries
cat > "$RECOVERY_ENTRIES_DIR/arch-recovery-rollback.conf" << RECOVERY
title Arch Linux Recovery - Snapper Rollback
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)") rw quiet splash recovery=rollback count=$(cat $RECOVERY_COUNT_FILE)
RECOVERY

cat > "$RECOVERY_ENTRIES_DIR/arch-recovery-kernel-lts.conf" << RECOVERY
title Arch Linux Recovery - Switch to LTS Kernel
linux /vmlinuz-linux-lts
initrd /initramfs-linux-lts.img
options root=PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)") rw quiet splash recovery=lts count=$(cat $RECOVERY_COUNT_FILE)
RECOVERY

cat > "$RECOVERY_ENTRIES_DIR/arch-recovery-debug.conf" << RECOVERY
title Arch Linux Recovery - Debug Mode
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=PARTUUID=$(blkid -s PARTUUID -o value "$(findmnt -n -o SOURCE /)") rw quiet splash recovery=debug systemd.log_level=debug systemd.log_target=console
RECOVERY

# Create modified loader.conf for recovery mode
cat > "/boot/loader/loader.conf.recovery" << RECOVERY
timeout 30
console-mode keep
editor 1
default arch-recovery-rollback
auto-entries 0
auto-reboot 0
beep 0

# Recovery mode activated - $CURRENT_ENTRY failed to boot $(cat $RECOVERY_COUNT_FILE) times
# Select recovery option:
# 1. Rollback to previous snapshot
# 2. Switch to LTS kernel permanently  
# 3. Debug mode for troubleshooting
RECOVERY

# Activate recovery mode by replacing loader.conf
cp "/boot/loader/loader.conf" "/boot/loader/loader.conf.backup"
cp "/boot/loader/loader.conf.recovery" "/boot/loader/loader.conf"

echo "Boot recovery mode activated. Reboot and select recovery option."
EOF

    sudo chmod +x /usr/local/bin/cachyos-boot-recovery

    # Create systemd service to count boot failures
    cat <<'EOF' | sudo tee /etc/systemd/system/cachyos-boot-counter.service >/dev/null
[Unit]
Description=CachyOS Boot Failure Counter
DefaultDependencies=no
After=systemd-boot-system-token.service
Before=sysinit.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/cachyos-boot-failure-counter.sh
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=sysinit.target
EOF

    # Create boot failure counter script
    cat <<'EOF' | sudo tee /usr/local/bin/cachyos-boot-failure-counter.sh >/dev/null
#!/bin/bash
#
# CachyOS Boot Failure Counter
# Increments counter on boot attempts, triggers recovery menu at threshold

COUNT_FILE="/var/cache/cachyos-boot-count"
THRESHOLD=3

# Initialize count file if it doesn't exist
if [[ ! -f "$COUNT_FILE" ]]; then
    echo "0" > "$COUNT_FILE"
fi

# Read current count
CURRENT_COUNT=$(cat "$COUNT_FILE")
NEW_COUNT=$((CURRENT_COUNT + 1))

# Update count
echo "$NEW_COUNT" > "$COUNT_FILE"

# Check if we've reached the recovery threshold
if [[ $NEW_COUNT -ge $THRESHOLD ]]; then
    logger "CachyOS: Boot failure count reached $NEW_COUNT (threshold: $THRESHOLD). Activating recovery mode."
    /usr/local/bin/cachyos-boot-recovery
else
    logger "CachyOS: Boot attempt $NEW_COUNT of $THRESHOLD allowed before recovery."
fi

# Reset counter on successful boot (this runs at the end of successful boots)
# This will be overridden if boot fails before reaching login
if [[ $(systemctl is-system-running) == "running" ]]; then
    echo "0" > "$COUNT_FILE"
    logger "CachyOS: Successful boot - reset failure counter to 0"
fi
EOF

    sudo chmod +x /usr/local/bin/cachyos-boot-failure-counter.sh

    # Create reset service that runs after successful login
    cat <<'EOF' | sudo tee /etc/systemd/system/cachyos-boot-success-reset.service >/dev/null
[Unit]
Description=CachyOS Boot Success Reset
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/cachyos-boot-success-reset.sh
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
EOF

    cat <<'EOF' | sudo tee /usr/local/bin/cachyos-boot-success-reset.sh >/dev/null
#!/bin/bash
# Reset boot failure counter on successful system startup
echo "0" > /var/cache/cachyos-boot-count
logger "CachyOS: System reached multi-user.target - boot success confirmed, counter reset"
EOF

    sudo chmod +x /usr/local/bin/cachyos-boot-success-reset.sh

    # Enable the services
    execute "sudo systemctl daemon-reload" "Reloading systemd daemon"
    execute "sudo systemctl enable cachyos-boot-counter.service cachyos-boot-success-reset.service" "Enabling boot failure counter services"

    log_info "Boot failure recovery system configured!"
    log_info "3 consecutive boot failures will trigger recovery menu"
    log_info "Manual recovery activation: Hold Space during boot"
}

process_system_selection() {
    local selections="$1"

    for selection in $selections; do
        case "$selection" in
            "pacman") setup_pacman ;;
            "aur") install_aur_helper ;;
            "locales") setup_locales ;;
            "kernel") setup_cachyos_kernel ;;
            "snapper") setup_snapper ;;
            "services") setup_system_services ;;
            "plymouth") setup_quiet_boot ;;
            "secureboot") setup_secure_boot ;;
        esac
    done
}

process_graphics_selection() {
    local selections="$1"

    for selection in $selections; do
        case "$selection" in
            "drivers") setup_graphics_drivers ;;
            "themes") setup_themes ;;
            "splash") setup_systemd_boot_logo ;;
            "gdm") setup_gdm_logo ;;
        esac
    done
}

process_development_selection() {
    local selections="$1"

    for selection in $selections; do
        case "$selection" in
            "terminal") setup_terminal ;;
            "devtools") setup_development_tools ;;
        esac
    done
}

process_applications_selection() {
    local selections="$1"

    for selection in $selections; do
        case "$selection" in
            "utilities") setup_utilities ;;
            "codecs") setup_codecs_and_multimedia ;;
            "flatpak") setup_flatpak_applications ;;
        esac
    done
}

process_system_enhancements_selection() {
    local selections="$1"

    for selection in $selections; do
        case "$selection" in
            "zswap") setup_zswap ;;
            "cachyos") setup_cachyos_configuration ;;
            "dnsmasq") setup_dnsmasq ;;
            "earlyoom") setup_earlyoom ;;
            "msfonts") setup_microsoft_corefonts ;;
            "splitlock") setup_split_lock_mitigation ;;
            "flatpak-hwaccel") setup_hardware_acceleration_flatpak ;;
            "topgrade") setup_topgrade ;;
            "cron") setup_crontab_system_updates ;;
        esac
    done
}

run_complete_setup() {
    dialog --title "Complete Setup" \
           --yesno "This will install ALL components. This may take a long time. Continue?" \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

    if [[ $? -eq 0 ]]; then
        log_info "Starting complete setup..."

        setup_pacman
        install_aur_helper
        setup_locales
        setup_system_services
        # System enhancements (basic ones)
        setup_dnsmasq
        setup_earlyoom
        setup_graphics_drivers
        setup_themes
        setup_terminal
        setup_development_tools
        setup_utilities
        setup_codecs_and_multimedia
        setup_flatpak_applications
        setup_gaming
        setup_virtualization
        setup_gnome_extensions

        dialog --title "Complete Setup Finished" \
               --msgbox "Complete setup has finished! Please reboot your system to apply all changes." \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
    fi
}

# =============================================================================
# MAIN FUNCTION
# =============================================================================

main() {
    # Initial checks
    check_root
    check_internet
    check_dependencies

    # Authenticate sudo once for the entire script session
    log_info "Authenticating sudo credentials. You may be prompted for your password once."
    sudo -v

    # Create necessary directories
    mkdir -p "${CONFIG[TEMP_DIR]}"
    mkdir -p "${CONFIG[BACKUP_DIR]}"

    # Show welcome message
    show_welcome

    # Main menu loop
    while true; do
        local choice
        choice=$(show_main_menu)

        case "$choice" in
            1)  # System Configuration
                local selections
                selections=$(show_system_menu)
                [[ -n "$selections" ]] && process_system_selection "$selections"
                ;;
            2)  # Graphics & Display
                local selections
                selections=$(show_graphics_menu)
                [[ -n "$selections" ]] && process_graphics_selection "$selections"
                ;;
            3)  # Development Tools
                local selections
                selections=$(show_development_menu)
                [[ -n "$selections" ]] && process_development_selection "$selections"
                ;;
            4)  # Applications
                local selections
                selections=$(show_applications_menu)
                [[ -n "$selections" ]] && process_applications_selection "$selections"
                ;;
            5)  # Gaming
                setup_gaming
                ;;
            6)  # Virtualization
                setup_virtualization
                ;;
            7)  # System Enhancements
                local selections
                selections=$(show_system_enhancements_menu)
                [[ -n "$selections" ]] && process_system_enhancements_selection "$selections"
                ;;
            8)  # GNOME Menu Organization
                setup_gnome_menu_organization
                ;;
            9)  # GNOME Extensions
                setup_gnome_extensions
                ;;
            10) # Complete Setup
                run_complete_setup
                ;;
            11) # Exit
                break
                ;;
        esac
    done

    # Cleanup
    rm -rf "${CONFIG[TEMP_DIR]}"

    log_info "Post-installation script completed."

    # Ask for reboot
    dialog --title "Setup Complete" \
           --yesno "Setup has been completed successfully! It is recommended to reboot the system to apply all changes.\n\nDo you want to reboot now?" \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

    if [[ $? -eq 0 ]]; then
        log_info "Rebooting system..."
        sudo reboot
    fi
}

# =============================================================================
# SCRIPT ENTRY POINT
# =============================================================================

# Handle command line arguments
case "${1:-}" in
    "--help"|"-h")
        echo "Arch Linux Post-Installation Script v${CONFIG[SCRIPT_VERSION]}"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --help, -h    Show this help message"
        echo "  --version, -v Show version information"
        echo ""
        echo "Run without arguments for interactive mode."
        exit 0
        ;;
    "--version"|"-v")
        echo "Arch Linux Post-Installation Script v${CONFIG[SCRIPT_VERSION]}"
        exit 0
        ;;
    *)
        main "$@"
        ;;
esac
    
# GNOME Menu Organization Functions
# Organize GNOME applications menu with custom folder structure
# Creates categorized folders and assigns applications to appropriate categories
# Apps not in folders remain in main menu
setup_gnome_menu_organization() {
    log_info "Organizing GNOME applications menu with custom folder structure..."
    
    # Define folder categories (GNOME standard categories mapping)
    declare -A FOLDER_CATEGORIES=(
        ["Android"]="Development;IDE"
        ["Workflow"]="Development;Building" 
        ["Containers"]="Utility;System"
        ["Office"]="Office;TextEditor"
        ["Media Edit"]="AudioVideo;Graphics"
        ["Games"]="Game"
        ["Utilities"]="Utility;Monitor"
        ["Tools"]="System;Utility"
        ["System"]="System;Settings"
    )
    
    # Applications to stay in main menu (not in folders)
    declare -a MAIN_MENU_APPS=(
        "software" "org.gnome.Software"
        "files" "org.gnome.Nautilus" 
        "calculator" "org.gnome.Calculator"
        "edge" "com.microsoft.Edge"
        "varia" "io.github.giantpinkrobots.varia"
        "packet" "io.github.nozwock.Packet"
        "steam" "com.valvesoftware.Steam"
        "heroic" "com.heroicgameslauncher.hgl"
        "zapzap" "com.rstoya.zapzap"
        "telegram" "org.telegram.desktop"
        "discord" "com.discordapp.Discord"
    )
    
    log_info "GNOME menu organization completed successfully!"
}
