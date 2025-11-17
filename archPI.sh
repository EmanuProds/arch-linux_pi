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

# Initialize script directories before any function calls
_SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
_ARCHPI_DIR="$HOME/.archPI"
mkdir -p "$_ARCHPI_DIR/temp"
mkdir -p "$_ARCHPI_DIR/backup"

# Global variables
SUDO_KEEPALIVE_PID=""
declare -a to_execute=()

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================

# Global configuration array containing all script settings
# This associative array centralizes all configurable paths and parameters
declare -A CONFIG=(
    ["SCRIPT_VERSION"]="3.1.0"              # Current script version for changelog and compatibility
    ["TEMP_DIR"]="$_ARCHPI_DIR/temp"        # Temporary directory for build files and downloads
    ["BACKUP_DIR"]="$_ARCHPI_DIR/backup"    # Directory to store configuration backups
    ["LOG_FILE"]="$_ARCHPI_DIR/archpi.log"  # Main log file for script execution tracking
    ["ASSETS_DIR"]="$_SCRIPT_DIR/assets"    # Directory containing custom assets (logos, themes)
    ["DIALOG_HEIGHT"]=20                    # Default height for dialog menus
    ["DIALOG_WIDTH"]=70                     # Default width for dialog menus
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
# USER CONFIGURABLE CONSTANTS
# =============================================================================

# System dependencies (required for script operation)
readonly DEPENDENCIES=(
    "dialog"
    "curl"
    "git"
)

# Pacman configuration settings
readonly PACMAN_PARALLEL_DOWNLOADS=15
readonly PACMAN_CLEAN_METHOD="KeepCurrent"

# System utilities packages
readonly SYSTEM_UTILITIES=(
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

# Multimedia codecs packages
readonly MULTIMEDIA_CODECS=(
    "ffmpeg" "gst-plugins-ugly" "gst-plugins-good"
    "gst-plugins-base" "gst-plugins-bad" "gst-libav" "gstreamer"
)

# Flatpak applications by category
readonly FLATPAK_BROWSERS=(
    "app.zen_browser.zen"
    "com.microsoft.Edge"
    "io.github.giantpinkrobots.varia"
)

readonly FLATPAK_COMMUNICATION=(
    "de.capypara.FieldMonitor"
    "com.rustdesk.RustDesk"
    "com.anydesk.Anydesk"
    "com.freerdp.FreeRDP"
    "com.rstoya.zapzap"
    "org.telegram.desktop"
    "com.discordapp.Discord"
)

readonly FLATPAK_DEVELOPMENT=(
    "io.dbeaver.DBeaverCommunity"
    "me.iepure.devtoolbox"
    "io.podman_desktop.PodmanDesktop"
    "sh.loft.devpod"
    "rest.insomnia.Insomnia"
    "com.google.AndroidStudio"
    "re.sonny.Workbench"
)

readonly FLATPAK_SYSTEM_UTILITIES=(
    "net.nokyan.Resources"
    "com.mattjakeman.ExtensionManager"
    "io.github.flattool.Ignition"
    "com.github.tchx84.Flatseal"
    "io.github.flattool.Warehouse"
    "it.mijorus.gearlever"
    "com.ranfdev.DistroShelf"
    "page.codeberg.libre_menu_editor.LibreMenuEditor"
    "io.github.realmazharhussain.GdmSettings"
)

readonly FLATPAK_MULTIMEDIA=(
    "com.obsproject.Studio"
    "fr.handbrake.ghb"
    "org.nickvision.tubeconverter"
    "org.gimp.GIMP"
    "org.inkscape.Inkscape"
    "com.github.finefindus.eyedropper"
    "io.gitlab.adhami3310.Converter"
    "io.gitlab.theevilskeleton.Upscaler"
    "org.tenacityaudio.Tenacity"
)

readonly FLATPAK_GAMING=(
    "com.steamgriddb.steam-rom-manager"
    "com.vysp3r.ProtonPlus"
    "com.github.Matoking.protontricks"
    "io.github.hedge_dev.hedgemodmanager"
    "io.github.radiolamp.mangojuice"
    "org.openrgb.OpenRGB"
    "org.prismlauncher.PrismLauncher"
    "io.mrarm.mcpelauncher"
    "net.veloren.airshipper"
    "org.vinegarhq.Sober"
    "net.rpcs3.RPCS3"
    "org.DolphinEmu.dolphin-emu"
    "net.pcsx2.PCSX2"
    "org.ppsspp.PPSSPP"
    "org.duckstation.DuckStation"
    "org.libretro.RetroArch"
)

readonly FLATPAK_ADDITIONAL=(
    "md.obsidian.Obsidian"
    "io.github.nozwock.Packet"
    "io.gitlab.adhami3310.Impression"
    "garden.jamie.Morphosis"
    "io.github.diegoivan.pdf_metadata_editor"
)

# Development tools packages
readonly DEVELOPMENT_PACKAGES=(
    "base-devel" "git" "github-cli" "openssl-devel" "distrobox" "docker-ce" "docker-compose-plugin" "scrcpy" "heimdall-frontend" "zed-editor" "figma-linux" "tailscale" "pnpm" "mise" "starship" "jdk-openjdk"
)

# Gaming packages
readonly GAMING_PACKAGES=(
    "arch-gaming-meta" "wine-installer" "proton-ge-custom-bin" "gamemode" "lib32-gamemode" "citron" "input-remapper" "heroic-games-launcher" "shader-boost" "steam"
)

# Virtualization packages
readonly VIRTUALIZATION_PACKAGES=(
    "qemu" "libvirt" "virt-viewer" "spice-gtk" "gnome-boxes" "winboat"
)

# Theme packages
readonly THEME_PACKAGES=(
    "morewaita-icon-theme" "adwaita-colors-icon-theme" "adw-gtk-theme"
)

# GNOME Extensions (compatible with GNOME 49)
readonly GNOME_EXTENSIONS=(
    "adw-gtk3-colorizer@NiffirgkcaJ.github.com"
    "arch-update@RaphaelRochet"
    "auto-power-profile@dmy3k.github.io"
    "Bluetooth-Battery-Meter@maniacx.github.com"
    "caffeine@patapon.info"
    "grand-theft-focus@zalckos.github.com"
    "gsconnect@andyholmes.github.io"
    "hide-universal-access@akiirui.github.io"
    "hotedge@jonathan.jdoda.ca"
    "monitor-brightness-volume@ailin.nemui"
    "notification-icons@muhammad_ans.github"
    "power-profile@fthx"
    "printers@linux-man.org"
    "rounded-window-corners@fxgn"
    "system-monitor@gnome-shell-extensions.gcampax.github.com"
    "window-title-is-back@fthx"
)

# GPU driver packages by type
readonly NVIDIA_PACKAGES=(
    "nvidia-dkms" "nvidia-utils" "lib32-nvidia-utils" "nvidia-settings"
    "vulkan-icd-loader" "lib32-vulkan-icd-loader"
)

readonly AMD_PACKAGES=(
    "mesa" "lib32-mesa" "vulkan-radeon" "lib32-vulkan-radeon"
    "libva-mesa-driver" "lib32-libva-mesa-driver" "vulkan-icd-loader" "lib32-vulkan-icd-loader"
)

readonly INTEL_PACKAGES=(
    "mesa" "lib32-mesa" "vulkan-intel" "lib32-vulkan-intel"
    "intel-media-driver" "vulkan-icd-loader" "lib32-vulkan-icd-loader"
)

readonly GENERIC_GPU_PACKAGES=(
    "mesa" "lib32-mesa" "vulkan-icd-loader" "lib32-vulkan-icd-loader"
)

# System services packages
readonly SYSTEM_SERVICES_PACKAGES=(
    "cups" "bluez" "bluez-utils"
)

# Zswap configuration
readonly ZSWAP_SIZE_DEFAULT=20

# DNSMasq configuration
readonly DNSMASQ_SERVERS=(
    "1.1.1.1"
    "8.8.8.8"
)

# EarlyOOM configuration
readonly EARLYOOM_ARGS="-m 1 -r 0 -s 100 -n --avoid '(^|/)(init|Xorg|systemd|sshd|dbus|gdm|gnome|gjs|chromium)$'"

# =============================================================================
# ADVANCED USER CONFIGURABLE CONSTANTS
# =============================================================================
#
# These constants control advanced system settings and can be modified by users
# who want to customize the behavior of various system components.
#
# WARNING: Only modify these if you understand the implications!
# Incorrect values may affect system performance or stability.
#
# Common customizations:
# - Reduce REFLECTOR_TIMEOUT_* if you have slow internet
# - Adjust SNAPPER_TIMELINE_* values based on your storage capacity
# - Change ZSWAP_COMPRESSOR to "lz4" for faster compression (less CPU usage)
# - Modify ZSWAP_MAX_POOL_PERCENT if you want to limit RAM usage
#

# Reflector configuration (mirror optimization)
# These settings control how Pacman mirrors are selected and updated
readonly REFLECTOR_TIMEOUT_RATE=45         # Timeout for rate sorting method (seconds) - faster but may timeout
readonly REFLECTOR_TIMEOUT_AGE=30          # Timeout for age sorting method (seconds) - more reliable
readonly REFLECTOR_MIRRORS_COUNTRY=10      # Number of mirrors to fetch per country
readonly REFLECTOR_MIRRORS_WORLDWIDE=12    # Number of worldwide mirrors as fallback

# Snapper configuration (BTRFS snapshots)
# Controls automatic snapshot retention policy for system backups
readonly SNAPPER_TIMELINE_HOURLY=0         # Hourly snapshots to keep (0 = disabled)
readonly SNAPPER_TIMELINE_DAILY=2          # Daily snapshots to keep
readonly SNAPPER_TIMELINE_WEEKLY=14        # Weekly snapshots to keep
readonly SNAPPER_TIMELINE_MONTHLY=60       # Monthly snapshots to keep
readonly SNAPPER_TIMELINE_YEARLY=0         # Yearly snapshots to keep (0 = disabled)
readonly SNAPPER_EMPTY_PRE_POST_AGE=1800   # Minimum age for cleanup (seconds)

# Zswap configuration (compressed RAM swap)
# Advanced memory compression settings for better performance
readonly ZSWAP_COMPRESSOR="zstd"           # Compression algorithm: zstd (fast), lz4 (faster), lzo (fastest)
readonly ZSWAP_ZPOOL="zsmalloc"            # Memory allocator: zsmalloc (recommended), z3fold (alternative)
readonly ZSWAP_MAX_POOL_PERCENT=100        # Maximum pool percentage of RAM (100 = use all available)
readonly ZSWAP_PAGE_SIZE=4096              # System page size in bytes (usually 4096)

# Automatic system updates configuration (cron)
# Controls when and how system updates are performed automatically
readonly AUTO_UPDATE_HOUR=12               # Hour to run updates (0-23)
readonly AUTO_UPDATE_MINUTE=0              # Minute to run updates (0-59)
readonly AUTO_UPDATE_DAYS="0,2,4,6"        # Days of week: 0=Sun, 2=Tue, 4=Thu, 6=Sat
readonly AUTO_UPDATE_LOG_FILE="/var/log/system-auto-update.log"
readonly AUTO_UPDATE_LOCK_FILE="/var/run/system-auto-update.lock"
readonly AUTO_UPDATE_SCRIPT="/usr/local/bin/system-auto-update.sh"
readonly AUTO_UPDATE_HEALTHCHECK_URL="https://hc-ping.com/YOUR_HEALTHCHECK_ID_HERE"  # Optional health check URL

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

# Check if a command exists in the system PATH
# Arguments:
#   $1 - Command name to check
# Returns:
#   0 if command exists, 1 otherwise
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Check if script is running as root (should not be for user operations)
# Returns:
#   0 if not root (correct), 1 if root (error)
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for user-specific operations."
        return 1
    fi
    return 0
}

# Create timestamped backup of file before modification
# Backups are stored in ~/.archPI/backup with timestamp
# Arguments:
#   $1 - File path to backup
backup_file() {
    local file="$1"
    local backup="${CONFIG[BACKUP_DIR]}/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"

    if [[ -f "$file" ]]; then
        mkdir -p "${CONFIG[BACKUP_DIR]}"
        sudo cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Execute command with error handling and logging
# Arguments:
#   $1 - Command to execute
#   $2 - Description of operation (optional)
# Returns:
#   0 on success, 1 on failure
execute() {
    local cmd="$1"
    local description="${2:-Executing command}"

    log_info "$description..."
    if eval "$cmd" 2>&1 | tee -a "${CONFIG[LOG_FILE]}"; then
        log_info "✓ $description completed successfully"
        return 0
    else
        log_error "✗ $description failed"
        return 1
    fi
}

# Check internet connectivity by pinging reliable DNS servers
# Returns:
#   0 if connected, 1 if no connection
check_internet() {
    if ! ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
        log_error "No internet connection detected. Please check your network."
        return 1
    fi
    return 0
}

# Cleanup sudo keep-alive process
cleanup_sudo() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill -0 "$SUDO_KEEPALIVE_PID" 2>/dev/null; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    fi
}

# =============================================================================
# DEPENDENCY CHECKS
# =============================================================================

# Check and install required dependencies for the script
# Automatically installs missing dependencies from DEPENDENCIES array
# Exits if dependencies cannot be installed
check_dependencies() {
    local missing=()

    log_info "Checking required dependencies..."

    # Identify missing dependencies
    for dep in "${DEPENDENCIES[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done

    # Return if all dependencies are present
    if [[ ${#missing[@]} -eq 0 ]]; then
        log_info "All required dependencies are installed"
        return 0
    fi

    log_info "Missing required dependencies: ${missing[*]}"
    log_info "Installing dependencies automatically..."

    # Attempt to install missing dependencies
    if sudo pacman -S --noconfirm "${missing[@]}" 2>&1 | tee -a "${CONFIG[LOG_FILE]}"; then
        log_info "✓ All dependencies successfully installed"
        return 0
    else
        log_error "Failed to install dependencies automatically"
        log_info "Please install them manually: sudo pacman -S ${missing[*]}"
        exit 1
    fi
}

# =============================================================================
# SYSTEM CONFIGURATION FUNCTIONS
# =============================================================================

# Validate and clean pacman configuration
# Removes invalid repositories and fixes common configuration issues
validate_pacman_conf() {
    log_info "Validating pacman configuration..."

    local needs_cleanup=false

    # Check for invalid custom repositories
    if grep -q "\[custom\]" /etc/pacman.conf 2>/dev/null; then
        log_warn "Found invalid [custom] repository"
        needs_cleanup=true
    fi

    # Check for non-existent repository paths
    if grep -q "Server.*file://" /etc/pacman.conf 2>/dev/null; then
        log_warn "Found file:// repositories that may not exist"
        needs_cleanup=true
    fi

    # Check for comment blocks that got uncommented in repository sections
    if grep -E "^(An example of|tips on creating|details on options)" /etc/pacman.conf 2>/dev/null; then
        log_warn "Found invalid directives (uncommented comments)"
        needs_cleanup=true
    fi

    # Clean up if necessary
    if [[ "$needs_cleanup" == true ]]; then
        backup_file "/etc/pacman.conf"

        # Remove invalid custom repository sections
        sudo sed -i '/^\[custom\]/,/^$/d' /etc/pacman.conf

        # Remove invalid file:// repositories
        sudo sed -i '/Server.*file:\/\//d' /etc/pacman.conf

        # Remove all uncommented comment lines (more aggressive cleaning)
        sudo sed -i '/^An example of/d' /etc/pacman.conf
        sudo sed -i '/^tips on creating/d' /etc/pacman.conf
        sudo sed -i '/^details on options/d' /etc/pacman.conf
        sudo sed -i '/^See the pacman/d' /etc/pacman.conf
        sudo sed -i '/^for more information/d' /etc/pacman.conf

        log_info "Cleaned up invalid repositories from pacman.conf"
    else
        log_info "Pacman configuration is valid"
    fi

    # Remove stale lock file if it exists
    if [[ -f /var/lib/pacman/db.lck ]]; then
        log_warn "Found stale pacman lock file. Removing..."
        sudo rm -f /var/lib/pacman/db.lck
    fi

    return 0
}

# Configure Pacman with optimizations and enable multilib repository
# Enables: Color, VerbosePkgLists, multilib, ParallelDownloads
# Adds CleanMethod KeepCurrent to keep current package versions
setup_pacman() {
    log_info "Configuring Pacman with optimizations..."

    # Validate configuration first
    validate_pacman_conf

    # Backup original configuration
    backup_file "/etc/pacman.conf"

    # Modify pacman.conf to enable desired options
    log_info "Modifying pacman.conf to enable optimizations..."

    # Uncomment or add Color
    if grep -q "^#Color" /etc/pacman.conf; then
        sudo sed -i 's/^#Color$/Color/' /etc/pacman.conf
    elif ! grep -q "^Color" /etc/pacman.conf; then
        sudo sed -i '/^\[options\]/a Color' /etc/pacman.conf
    fi

    # Uncomment or add CheckSpace
    if grep -q "^#CheckSpace" /etc/pacman.conf; then
        sudo sed -i 's/^#CheckSpace$/CheckSpace/' /etc/pacman.conf
    elif ! grep -q "^CheckSpace" /etc/pacman.conf; then
        sudo sed -i '/^\[options\]/a CheckSpace' /etc/pacman.conf
    fi

    # Set ParallelDownloads
    if grep -q "^ParallelDownloads" /etc/pacman.conf; then
        sudo sed -i "s/^ParallelDownloads.*/ParallelDownloads = $PACMAN_PARALLEL_DOWNLOADS/" /etc/pacman.conf
    else
        sudo sed -i "/^\[options\]/a ParallelDownloads = $PACMAN_PARALLEL_DOWNLOADS" /etc/pacman.conf
    fi

    # Set CleanMethod
    if grep -q "^CleanMethod" /etc/pacman.conf; then
        sudo sed -i "s/^CleanMethod.*/CleanMethod = $PACMAN_CLEAN_METHOD/" /etc/pacman.conf
    else
        sudo sed -i "/^\[options\]/a CleanMethod = $PACMAN_CLEAN_METHOD" /etc/pacman.conf
    fi

    # Enable multilib repository if not present
    if ! grep -q "\[multilib\]" /etc/pacman.conf; then
        log_info "Enabling multilib repository..."
        echo "" | sudo tee -a /etc/pacman.conf > /dev/null
        echo "[multilib]" | sudo tee -a /etc/pacman.conf > /dev/null
        echo "Include = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null
    fi

    log_info "✓ Pacman.conf configured with optimizations"

    # Synchronize package databases
    log_info "Synchronizing package databases..."
    if ! sudo pacman -Sy --noconfirm 2>&1 | tee -a "${CONFIG[LOG_FILE]}"; then
        log_error "Database synchronization failed. Attempting recovery..."
        sudo rm -rf /var/lib/pacman/sync/*
        sudo pacman -Sy --noconfirm
    fi
}

# Install and configure reflector for optimal mirror selection
# Automatically selects fastest mirrors from user's region with intelligent fallbacks
setup_reflector() {
    log_info "Setting up Reflector for mirror optimization..."

    # Ask user if they want to update mirrors
    dialog --title "Mirror Update" \
           --yesno "Do you want to update your mirror list?\n\nThis will select the fastest mirrors from your region.\n\nSkip if you have connection issues." \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

    if [[ $? -ne 0 ]]; then
        log_info "Skipping mirror update, using default mirrors"
        return 0
    fi

    # Install reflector if not present
    if ! check_command "reflector"; then
        execute "sudo pacman -S --noconfirm reflector" "Installing Reflector"
    fi

    # Detect user's country based on timezone or ask
    local default_country="Brazil"
    if [[ -f /etc/timezone ]]; then
        local tz=$(cat /etc/timezone)
        case "$tz" in
            America/Sao_Paulo|America/Fortaleza|America/Recife|America/Manaus) default_country="Brazil" ;;
            America/New_York|America/Los_Angeles|America/Chicago) default_country="United States" ;;
            Europe/London) default_country="United Kingdom" ;;
            Europe/Paris) default_country="France" ;;
            Europe/Berlin) default_country="Germany" ;;
            Europe/Madrid) default_country="Spain" ;;
            Asia/Tokyo) default_country="Japan" ;;
            Asia/Shanghai) default_country="China" ;;
        esac
    fi

    # Get user's country for mirror selection
    local country
    country=$(dialog --title "Reflector Mirror Selection" \
                     --inputbox "Enter your country for mirror selection:\n\n(Examples: Brazil, United States, Germany, France)" \
                     ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} "$default_country" \
                     2>&1 >/dev/tty)

    if [[ -z "$country" ]]; then
        country="$default_country"
        log_info "Using default country: $country"
    fi

    # Backup current mirrorlist
    backup_file "/etc/pacman.d/mirrorlist"

    log_info "Updating mirrorlist for $country..."
    log_info "This may take 30-60 seconds..."

    # Try Method 1: Country-specific with rate sort (fastest but may timeout)
    log_info "Attempting to get fastest mirrors from $country..."
    if timeout $REFLECTOR_TIMEOUT_RATE sudo reflector --country "$country" --latest $REFLECTOR_MIRRORS_COUNTRY --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>&1 | grep -v "TimeoutError" | tee -a "${CONFIG[LOG_FILE]}"; then
        log_info "✓ Mirrorlist updated successfully with $country mirrors (sorted by speed)"
        execute "sudo pacman -Syy --noconfirm" "Synchronizing with new mirrors"
        return 0
    fi

    # Try Method 2: Country-specific without rate sort (faster, less likely to timeout)
    log_warn "Rate sorting timed out, trying simpler method for $country..."
    if timeout $REFLECTOR_TIMEOUT_AGE sudo reflector --country "$country" --latest $REFLECTOR_MIRRORS_COUNTRY --protocol https --sort age --save /etc/pacman.d/mirrorlist 2>&1 | grep -v "TimeoutError" | tee -a "${CONFIG[LOG_FILE]}"; then
        log_info "✓ Mirrorlist updated with $country mirrors (sorted by update time)"
        execute "sudo pacman -Syy --noconfirm" "Synchronizing with new mirrors"
        return 0
    fi

    # Try Method 3: Worldwide fastest (no country filter)
    log_warn "Country-specific mirrors failed, trying worldwide fastest mirrors..."
    if timeout $REFLECTOR_TIMEOUT_AGE sudo reflector --latest $REFLECTOR_MIRRORS_WORLDWIDE --protocol https --sort age --save /etc/pacman.d/mirrorlist 2>&1 | grep -v "TimeoutError" | tee -a "${CONFIG[LOG_FILE]}"; then
        log_info "✓ Mirrorlist updated with worldwide mirrors"
        execute "sudo pacman -Syy --noconfirm" "Synchronizing with new mirrors"
        return 0
    fi

    # Fallback: Restore original mirrorlist
    log_error "All reflector methods failed, restoring original mirrorlist"
    if [[ -f "${CONFIG[BACKUP_DIR]}/mirrorlist.backup."* ]]; then
        sudo cp "${CONFIG[BACKUP_DIR]}"/mirrorlist.backup.* /etc/pacman.d/mirrorlist 2>/dev/null || true
        log_info "✓ Original mirrorlist restored - default mirrors will be used"
    else
        log_warn "No backup found, keeping current mirrorlist"
    fi
}

# Add Chaotic-AUR repository for additional packages
# Provides access to pre-built AUR packages and CachyOS kernels
setup_chaotic_aur() {
    log_info "Setting up Chaotic-AUR repository..."

    # Check if already configured
    if grep -q "\[chaotic-aur\]" /etc/pacman.conf 2>/dev/null; then
        log_info "Chaotic-AUR repository already configured"
        return 0
    fi

    # Backup pacman.conf
    backup_file "/etc/pacman.conf"

    # Install Chaotic-AUR keyring and mirrorlist
    log_info "Installing Chaotic-AUR keyring..."

    # Import primary key
    execute "sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com" "Importing Chaotic-AUR primary key"
    execute "sudo pacman-key --lsign-key 3056513887B78AEB" "Locally signing Chaotic-AUR key"

    # Install keyring and mirrorlist packages
    log_info "Installing Chaotic-AUR keyring and mirrorlist packages..."
    sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst' \
        2>&1 | tee -a "${CONFIG[LOG_FILE]}"

    # Add Chaotic-AUR repository to pacman.conf
    log_info "Adding Chaotic-AUR repository to pacman.conf..."
    echo "" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf > /dev/null
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf > /dev/null

    # Sync databases
    execute "sudo pacman -Syy --noconfirm" "Synchronizing Chaotic-AUR repository"

    log_info "✓ Chaotic-AUR repository configured successfully"
}

# Add LizardByte repository for Sunshine game streaming
setup_lizardbyte_repo() {
    log_info "Setting up LizardByte repository for Sunshine..."

    # Check if already configured
    if grep -q "\[lizardbyte\]" /etc/pacman.conf 2>/dev/null; then
        log_info "LizardByte repository already configured"
        return 0
    fi

    # Backup pacman.conf
    backup_file "/etc/pacman.conf"

    # Add LizardByte repository to pacman.conf
    log_info "Adding LizardByte repository to pacman.conf..."
    cat <<'EOF' | sudo tee -a /etc/pacman.conf > /dev/null

[lizardbyte]
SigLevel = Optional
Server = https://github.com/LizardByte/pacman-repo/releases/latest/download
EOF

    # Sync databases
    execute "sudo pacman -Syy --noconfirm" "Synchronizing LizardByte repository"

    log_info "✓ LizardByte repository configured successfully"
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
    log_info "Configuring system services..."

    # Install service dependencies
    execute "sudo pacman -S --needed --noconfirm ${SYSTEM_SERVICES_PACKAGES[*]}" "Installing system services"

    # Enable Bluetooth
    execute "sudo systemctl enable --now bluetooth.service" "Enabling Bluetooth"

    # Enable CUPS printing
    execute "sudo systemctl enable --now cups.service" "Enabling CUPS"

    # Add user to necessary groups
    execute "sudo usermod -aG lp,scanner,storage $USER" "Adding user to groups"

    log_info "✓ System services configured"
}

# Configure Snapper for automatic system snapshots
# Creates snapshots before package updates and on timeline
setup_snapper() {
    log_info "Setting up Snapper for automatic system snapshots..."

    # Check if root filesystem is btrfs
    if ! findmnt -n -o FSTYPE / | grep -q "btrfs"; then
        log_error "Root filesystem is not btrfs. Snapper requires btrfs."
        dialog --title "Snapper Error" \
               --msgbox "Snapper requires a btrfs root filesystem.\n\nYour root filesystem is not btrfs. Skipping Snapper setup." \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
        return 1
    fi

    # Install Snapper and snap-pac first
    execute "sudo pacman -S --needed --noconfirm snapper snap-pac" "Installing Snapper and snap-pac"

    # Check if Snapper is already configured
    if [[ -f "/etc/snapper/configs/root" ]]; then
        log_info "Snapper is already configured for root filesystem"

        dialog --title "Snapper Already Configured" \
               --msgbox "Snapper is already configured with existing snapshots.\n\nThe script will update the configuration settings without deleting your snapshots." \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

        log_info "Updating existing Snapper configuration (preserving snapshots)..."
    else
        # Create Snapper configuration for root (first time setup)
        log_info "Creating Snapper configuration for root filesystem..."

        # Handle .snapshots directory safely for first-time setup
        if [[ -d "/.snapshots" ]]; then
            # Check if it's mounted
            if mountpoint -q /.snapshots; then
                log_info "Unmounting /.snapshots..."
                sudo umount /.snapshots || log_warn "Could not unmount /.snapshots"
            fi

            # Only remove if it's not a btrfs subvolume
            if ! sudo btrfs subvolume show /.snapshots &>/dev/null; then
                sudo rmdir /.snapshots 2>/dev/null || log_warn "/.snapshots not empty, will be handled by Snapper"
            fi
        fi

        sudo snapper -c root create-config /
    fi

    # Configure snapshot retention policy
    backup_file "/etc/snapper/configs/root"

    sudo tee "/etc/snapper/configs/root" > /dev/null <<EOF
# Snapper configuration for root filesystem
# Subvolume to snapshot
SUBVOLUME="/"

# Filesystem type
FSTYPE="btrfs"

# User and group permissions
ALLOW_USERS=""
ALLOW_GROUPS=""

# Sync ACL
SYNC_ACL="no"

# Timeline snapshots configuration
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"

# Snapshot limits
# Daily: Keep $SNAPPER_TIMELINE_DAILY snapshots per day
TIMELINE_LIMIT_HOURLY="$SNAPPER_TIMELINE_HOURLY"
TIMELINE_LIMIT_DAILY="$SNAPPER_TIMELINE_DAILY"
# Weekly: Keep $SNAPPER_TIMELINE_WEEKLY weekly snapshots
TIMELINE_LIMIT_WEEKLY="$SNAPPER_TIMELINE_WEEKLY"
# Monthly: Keep $SNAPPER_TIMELINE_MONTHLY monthly snapshots
TIMELINE_LIMIT_MONTHLY="$SNAPPER_TIMELINE_MONTHLY"
TIMELINE_LIMIT_YEARLY="$SNAPPER_TIMELINE_YEARLY"

# Empty pre-post pair settings
EMPTY_PRE_POST_CLEANUP="yes"
EMPTY_PRE_POST_MIN_AGE="$SNAPPER_EMPTY_PRE_POST_AGE"
EOF

    # Enable Snapper systemd timers
    execute "sudo systemctl enable --now snapper-timeline.timer" "Enabling Snapper timeline timer"
    execute "sudo systemctl enable --now snapper-cleanup.timer" "Enabling Snapper cleanup timer"

    # Create initial snapshot only if this is a new configuration
    if [[ ! -f "/etc/snapper/configs/root" ]] || [[ $(sudo snapper -c root list 2>/dev/null | wc -l) -le 2 ]]; then
        execute "sudo snapper -c root create -d 'Initial system snapshot after ArchPI setup'" "Creating initial snapshot"
    else
        log_info "Existing snapshots preserved, skipping initial snapshot creation"
    fi

    # Show current snapshot status
    local snapshot_count=$(sudo snapper -c root list 2>/dev/null | tail -n +3 | wc -l)
    log_info "✓ Snapper configured successfully"
    log_info "Current snapshots: $snapshot_count"
    log_info "Snapshot policy:"
    log_info "  - Before each package update (via snap-pac)"
    log_info "  - Hourly: $SNAPPER_TIMELINE_HOURLY snapshots kept"
    log_info "  - Daily: $SNAPPER_TIMELINE_DAILY snapshots kept"
    log_info "  - Weekly: $SNAPPER_TIMELINE_WEEKLY snapshots kept"
    log_info "  - Monthly: $SNAPPER_TIMELINE_MONTHLY snapshots kept"
    log_info "  - Yearly: $SNAPPER_TIMELINE_YEARLY snapshots kept"
}

# Setup perfect quiet boot with Arch splash, Plymouth spinner, and GDM
# Removes Plymouth watermark for clean appearance
setup_quiet_boot() {
    log_info "Setting up perfect quiet boot experience..."

    # Detect boot manager
    local boot_manager
    if [[ -d "/boot/loader" ]]; then
        boot_manager="systemd-boot"
    elif [[ -d "/boot/grub" ]]; then
        boot_manager="grub"
    else
        log_error "No supported boot manager detected"
        return 1
    fi

    # Install Plymouth with spinner theme
    log_info "Installing Plymouth with spinner theme..."
    execute "sudo pacman -S --noconfirm plymouth" "Installing Plymouth"

    # Configure Plymouth theme (spinner without watermark)
    backup_file "/etc/plymouth/plymouthd.conf"
    sudo tee /etc/plymouth/plymouthd.conf > /dev/null <<'EOF'
[Daemon]
Theme=spinner
ShowDelay=0
DeviceTimeout=8
EOF

    # Remove watermark from spinner theme if present
    if [[ -d "/usr/share/plymouth/themes/spinner" ]]; then
        sudo find /usr/share/plymouth/themes/spinner -name "*watermark*" -delete 2>/dev/null || true
        log_info "Removed watermark from Plymouth spinner theme"
    fi

    # Configure kernel parameters for quiet boot
    log_info "Configuring kernel parameters for quiet boot..."

    if [[ "$boot_manager" == "systemd-boot" ]]; then
        # Find all boot entries and add quiet splash parameters
        for entry in /boot/loader/entries/*.conf; do
            if [[ -f "$entry" ]]; then
                backup_file "$entry"

                # Add quiet splash if not present
                if ! grep -q "quiet splash" "$entry"; then
                    sudo sed -i 's/^options.*/& quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0/' "$entry"
                    log_info "Added quiet boot parameters to $(basename "$entry")"
                fi
            fi
        done

        sudo bootctl update 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Bootctl update skipped (same version)"
    elif [[ "$boot_manager" == "grub" ]]; then
        backup_file "/etc/default/grub"

        # Update GRUB_CMDLINE_LINUX_DEFAULT
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash loglevel=3 rd.udev.log_level=3 vt.global_cursor_default=0"/' /etc/default/grub

        execute "sudo grub-mkconfig -o /boot/grub/grub.cfg" "Regenerating GRUB configuration"
    fi

    # Setup Arch splash logo
    setup_arch_splash

    # Regenerate initramfs with Plymouth hook
    log_info "Regenerating initramfs with Plymouth support..."

    # Configure mkinitcpio.conf with proper hooks
    backup_file "/etc/mkinitcpio.conf"
    # Set HOOKS with plymouth
    sudo sed -i '/^HOOKS=/c\HOOKS=(base udev plymouth autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)' /etc/mkinitcpio.conf

    execute "sudo mkinitcpio -P" "Regenerating initramfs"

    log_info "✓ Quiet boot configured successfully"
    log_info "Boot sequence: Arch splash → Plymouth spinner (no watermark) → GDM"
}

# Setup Arch Linux splash logo for boot
setup_arch_splash() {
    log_info "Installing Arch Linux splash logo..."

    local splash_file="${CONFIG[ASSETS_DIR]}/logo/boot/splash-arch.bmp"

    if [[ ! -f "$splash_file" ]]; then
        log_warn "Arch splash logo not found at $splash_file"
        return 1
    fi

    # Copy splash logo to systemd-boot location
    sudo mkdir -p /usr/share/systemd/bootctl
    execute "sudo cp '$splash_file' /usr/share/systemd/bootctl/splash-arch.bmp" "Installing Arch splash logo"

    # Update systemd-boot if present
    if [[ -d "/boot/loader" ]]; then
        sudo bootctl update 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Bootctl update skipped (same version)"
    fi

    log_info "✓ Arch splash logo installed"
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
EOF

    # Add DNS servers
    for server in "${DNSMASQ_SERVERS[@]}"; do
        echo "server=$server" | sudo tee -a "/etc/dnsmasq.conf" > /dev/null
    done

    sudo tee -a "/etc/dnsmasq.conf" > /dev/null <<EOF
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
EARLYOOM_ARGS="$EARLYOOM_ARGS"
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
        zswap_size_gb=$ZSWAP_SIZE_DEFAULT
        selected_size="${ZSWAP_SIZE_DEFAULT}gb"
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
options zswap zpool=$ZSWAP_ZPOOL
options zswap compressor=$ZSWAP_COMPRESSOR
options zswap max_pool_percent=$ZSWAP_MAX_POOL_PERCENT
EOF

    log_info "Creating Zswap modprobe configuration with $ZSWAP_COMPRESSOR compression..."

    # Create sysctl configuration to set runtime parameters
    cat <<EOF | sudo tee "/etc/sysctl.d/99-zswap.conf" >/dev/null
# Zswap runtime configuration
# Maximum compressed pool size: ${zswap_size_gb}GB (${zswap_size_bytes} bytes)
vm.zswap.max_pool_pages = $(($zswap_size_bytes / $ZSWAP_PAGE_SIZE))
EOF

    # Create udev rule to load Zswap module on boot
    sudo mkdir -p /etc/udev/rules.d
    cat <<EOF | sudo tee "/etc/udev/rules.d/99-zswap.rules" >/dev/null
# Load zswap module early in boot process
ACTION=="add", KERNEL=="zswap", RUN+="/sbin/modprobe zswap enabled=1 compressor=$ZSWAP_COMPRESSOR zpool=$ZSWAP_ZPOOL same_filled_pages_enabled=1 max_pool_percent=$ZSWAP_MAX_POOL_PERCENT"
EOF

    # Apply sysctl settings immediately
    execute "sudo sysctl --load /etc/sysctl.d/99-zswap.conf" "Applying Zswap sysctl settings"

    # Load Zswap module if not already loaded
    if ! lsmod | grep -q zswap; then
        execute "sudo modprobe zswap enabled=1 compressor=$ZSWAP_COMPRESSOR zpool=$ZSWAP_ZPOOL same_filled_pages_enabled=1 max_pool_percent=$ZSWAP_MAX_POOL_PERCENT" "Loading Zswap module"
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
    log_info "Compression: $ZSWAP_COMPRESSOR (high performance)"
    log_info "Pool: $ZSWAP_ZPOOL (optimized allocator)"
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

    # Add cron job with retry logic (using configurable constants)
    backup_file "/etc/crontab"

    # Remove existing entries if any
    sudo sed -i '/system-auto-update/d' /etc/crontab

    # Parse days string into array for cron entries
    IFS=',' read -ra DAYS_ARRAY <<< "$AUTO_UPDATE_DAYS"

    # Add cron entries for each configured day
    cat <<EOF | sudo tee -a /etc/crontab > /dev/null

# System auto update - Runs on configured days at $AUTO_UPDATE_HOUR:$AUTO_UPDATE_MINUTE
EOF

    for day in "${DAYS_ARRAY[@]}"; do
        echo "$AUTO_UPDATE_MINUTE $AUTO_UPDATE_HOUR * * $day   root    $AUTO_UPDATE_SCRIPT" | sudo tee -a /etc/crontab > /dev/null
    done

    # Ensure cron service is enabled and running
    execute "sudo systemctl enable cronie" "Enabling cron service"
    execute "sudo systemctl start cronie" "Starting cron service"

    log_info "Automatic system updates configured!"
    log_info "Schedule: Sunday → Tuesday → Thursday → Saturday at 12:00"
    log_info "Logs available at: /var/log/system-auto-update.log"
    log_info "To monitor healthchecks, add your HC ping URL to the script"
}

# =============================================================================
# SYSTEM CONFIGURATION FUNCTIONS (continued)
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
            log_info "Installing NVIDIA drivers..."
            execute "sudo pacman -S --needed --noconfirm ${NVIDIA_PACKAGES[*]}" "Installing NVIDIA drivers"
            ;;
        "amd")
            log_info "Installing AMD drivers..."
            execute "sudo pacman -S --needed --noconfirm ${AMD_PACKAGES[*]}" "Installing AMD drivers"
            ;;
        "intel")
            log_info "Installing Intel drivers..."
            execute "sudo pacman -S --needed --noconfirm ${INTEL_PACKAGES[*]}" "Installing Intel drivers"
            ;;
        *)
            log_warn "Unknown GPU, installing generic Mesa drivers"
            execute "sudo pacman -S --needed --noconfirm ${GENERIC_GPU_PACKAGES[*]}" "Installing Mesa drivers"
            ;;
    esac

    log_info "✓ Graphics drivers installed"

    log_info "Graphics driver installation completed. A reboot may be required for changes to take effect."
}

setup_themes() {
    log_info "Setting up themes and appearance..."

    # Install theme packages via pacman (prefer native over AUR when possible)
    execute "paru -S --needed --noconfirm ${THEME_PACKAGES[*]}" "Installing themes"

    # Set GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme 'Adw-gtk3-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Adwaita-blue' 2>/dev/null || true

    log_info "✓ Themes configured"
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

# =============================================================================
# THEMES & OPTIMIZATION FUNCTIONS
# =============================================================================

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
    local user_extensions=("${GNOME_EXTENSIONS[@]}")

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

# =============================================================================
# THEMES & OPTIMIZATION FUNCTIONS (continued)
# =============================================================================

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

# Setup modern terminal environment with fish shell
# Installs fish shell and sets it as the default shell for better user experience
setup_terminal() {
    log_info "Setting up modern terminal environment with fish shell..."

    # Install fish shell - a smart and user-friendly command line shell
    execute "sudo pacman -S --noconfirm fish" "Installing fish shell"

    # Set fish as the default shell for the current user
    execute "sudo chsh -s /usr/bin/fish \"$USER\"" "Setting fish as default shell"
}

setup_development_tools() {
    log_info "Setting up development tools..."

    # Install development packages
    execute "sudo pacman -S --needed --noconfirm ${DEVELOPMENT_PACKAGES[*]}" "Installing development tools"

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
# APPLICATIONS & UTILITIES FUNCTIONS
# =============================================================================

setup_utilities() {
    log_info "Setting up system utilities..."

    execute "sudo pacman -S --needed --noconfirm ${SYSTEM_UTILITIES[*]}" "Installing system utilities"
}

setup_codecs_and_multimedia() {
    log_info "Setting up codecs and multimedia support..."

    execute "sudo pacman -S --needed --noconfirm ${MULTIMEDIA_CODECS[*]}" "Installing multimedia codecs"
}

setup_flatpak_applications() {
    log_info "Setting up Flatpak applications..."

    # Install Flatpak if not present
    if ! check_command "flatpak"; then
        execute "sudo pacman -S --noconfirm flatpak" "Installing Flatpak"
        execute "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" "Adding Flathub repository"
    fi

    log_info "Installing browser apps..."
    for app in "${FLATPAK_BROWSERS[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing communication apps..."
    for app in "${FLATPAK_COMMUNICATION[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing development apps..."
    for app in "${FLATPAK_DEVELOPMENT[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing system utilities..."
    for app in "${FLATPAK_SYSTEM_UTILITIES[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing multimedia apps..."
    for app in "${FLATPAK_MULTIMEDIA[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing gaming and emulation apps..."
    for app in "${FLATPAK_GAMING[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "Installing additional utilities..."
    for app in "${FLATPAK_ADDITIONAL[@]}"; do
        flatpak install flathub -y "$app" 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Failed to install $app"
    done

    log_info "✓ Flatpak applications installed"
}

# =============================================================================
# APPLICATIONS & UTILITIES FUNCTIONS (continued)
# =============================================================================

setup_gaming() {
    log_info "Setting up gaming environment..."

    execute "paru -S --needed --noconfirm ${GAMING_PACKAGES[*]}" "Installing gaming packages"

    # Enable GameMode
    if check_command "gamemoded"; then
        systemctl --user enable gamemoded 2>/dev/null || true
    fi

    log_info "✓ Gaming environment configured"
}

# =============================================================================
# APPLICATIONS & UTILITIES FUNCTIONS (continued)
# =============================================================================

setup_virtualization() {
    log_info "Setting up virtualization..."

    # Install virtualization packages
    execute "sudo pacman -S --needed --noconfirm ${VIRTUALIZATION_PACKAGES[*]}" "Installing virtualization tools"

    # Enable libvirt service
    execute "sudo systemctl enable --now libvirtd.service" "Enabling libvirt"

    # Add user to libvirt group
    execute "sudo usermod -aG libvirt $USER" "Adding user to libvirt group"

    log_info "✓ Virtualization configured"
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
EOF

    # Add DNS servers
    for server in "${DNSMASQ_SERVERS[@]}"; do
        echo "server=$server" | sudo tee -a "/etc/dnsmasq.conf" > /dev/null
    done

    sudo tee -a "/etc/dnsmasq.conf" > /dev/null <<EOF
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
EARLYOOM_ARGS="$EARLYOOM_ARGS"
EOF

    # Enable EarlyOOM
    execute "sudo systemctl enable earlyoom" "Enabling EarlyOOM service"
    execute "sudo systemctl start earlyoom" "Starting EarlyOOM service"

    log_info "EarlyOOM setup completed for better memory management!"
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

# Retry on Thursday 12:00 if Thursday failed
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
# INTERACTIVE MENUS
# =============================================================================

show_welcome() {
    dialog --title "ArchPI v${CONFIG[SCRIPT_VERSION]}" \
           --msgbox "Welcome to ArchPI - Arch Linux Post-Installation Script!\n\nThis script will help you set up your system with:\n- Optimized Pacman configuration\n- CachyOS kernels\n- Graphics drivers\n- Development tools\n- Applications and more\n\nSelect components from the main menu." \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
}

show_main_menu() {
    local choice
    choice=$(dialog --title "ArchPI Main Menu" \
                    --menu "Select a category:" \
                    ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]} 15 \
                    1 "System Configuration" \
                    2 "Graphics & Drivers" \
                    3 "Shell & Terminal" \
                    4 "Applications & Utilities" \
                    5 "Development Tools" \
                    6 "Gaming" \
                    7 "Multimedia & Codecs" \
                    8 "System Services" \
                    9 "Boot Configuration" \
                    10 "Themes & Appearance" \
                    11 "System Enhancements" \
                    12 "Cleanup & Optimization" \
                    13 "Complete Setup (All)" \
                    14 "Exit" \
                    2>&1 >/dev/tty)
    echo "$choice"
}

ask_confirmation() {
    local description="$1"
    local function_name="$2"
    dialog --title "Confirmation" \
           --yesno "$description\n\nExecute $function_name?" \
           ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
    return $?
}

collect_system_config() {
    if ask_confirmation "Configure Pacman with optimizations: Color, VerbosePkgLists, ParallelDownloads=15, CleanMethod=KeepCurrent, enable multilib." "setup_pacman"; then
        to_execute+=("setup_pacman")
    fi
    if ask_confirmation "Setup Reflector for fastest mirrors based on country selection." "setup_reflector"; then
        to_execute+=("setup_reflector")
    fi
    if ask_confirmation "Add Chaotic-AUR repository for additional packages." "setup_chaotic_aur"; then
        to_execute+=("setup_chaotic_aur")
    fi
    if ask_confirmation "Install AUR helper (paru)." "install_aur_helper"; then
        to_execute+=("install_aur_helper")
    fi
    if ask_confirmation "Setup system locales interactively." "setup_locales"; then
        to_execute+=("setup_locales")
    fi
    if ask_confirmation "Setup Snapper BTRFS snapshots." "setup_snapper"; then
        to_execute+=("setup_snapper")
    fi
}

collect_graphics() {
    if ask_confirmation "Detect and install appropriate graphics drivers (NVIDIA/AMD/Intel)." "setup_graphics_drivers"; then
        to_execute+=("setup_graphics_drivers")
    fi
}

collect_shell_terminal() {
    if ask_confirmation "Setup Fish shell with Starship prompt and development tools." "setup_terminal"; then
        to_execute+=("setup_terminal")
    fi
    if ask_confirmation "Install and configure GNOME Console as default terminal." "setup_terminal"; then
        to_execute+=("setup_terminal")
    fi
}

collect_applications() {
    if ask_confirmation "Add LizardByte repository." "setup_lizardbyte_repo"; then
        to_execute+=("setup_lizardbyte_repo")
    fi
    if ask_confirmation "Install system utilities (fastfetch, gparted, etc.)." "setup_utilities"; then
        to_execute+=("setup_utilities")
    fi
    if ask_confirmation "Install Flatpak applications (~20 apps across categories)." "setup_flatpak_applications"; then
        to_execute+=("setup_flatpak_applications")
    fi
}

collect_development() {
    if ask_confirmation "Install development tools (Docker, Node.js, Python, etc.)." "setup_development_tools"; then
        to_execute+=("setup_development_tools")
    fi
}

collect_gaming() {
    if ask_confirmation "Install gaming packages and Steam." "setup_gaming"; then
        to_execute+=("setup_gaming")
    fi
}

collect_multimedia() {
    if ask_confirmation "Install multimedia codecs and applications." "setup_codecs_and_multimedia"; then
        to_execute+=("setup_codecs_and_multimedia")
    fi
}

collect_services() {
    if ask_confirmation "Setup system services (Bluetooth, CUPS, etc.)." "setup_system_services"; then
        to_execute+=("setup_system_services")
    fi
}

collect_boot() {
    if ask_confirmation "Install CachyOS kernels with fallback." "setup_cachyos_kernel"; then
        to_execute+=("setup_cachyos_kernel")
    fi
    if ask_confirmation "Setup quiet boot with Plymouth splash." "setup_quiet_boot"; then
        to_execute+=("setup_quiet_boot")
    fi
    if ask_confirmation "Setup Secure Boot with sbctl." "setup_secure_boot"; then
        to_execute+=("setup_secure_boot")
    fi
}

collect_themes() {
    if ask_confirmation "Setup GNOME themes, icons, and organize menu folders." "setup_themes setup_gnome_menu_folders"; then
        to_execute+=("setup_themes")
        to_execute+=("setup_gnome_menu_folders")
    fi
}

collect_enhancements() {
    if ask_confirmation "Setup Zswap compressed swap." "setup_zswap"; then
        to_execute+=("setup_zswap")
    fi
    if ask_confirmation "Setup DNSMasq for DNS caching." "setup_dnsmasq"; then
        to_execute+=("setup_dnsmasq")
    fi
    if ask_confirmation "Setup EarlyOOM memory management." "setup_earlyoom"; then
        to_execute+=("setup_earlyoom")
    fi
    if ask_confirmation "Setup Topgrade system updater." "setup_topgrade"; then
        to_execute+=("setup_topgrade")
    fi
    if ask_confirmation "Setup Flatpak hardware acceleration." "setup_hardware_acceleration_flatpak"; then
        to_execute+=("setup_hardware_acceleration_flatpak")
    fi
    if ask_confirmation "Setup GNOME extensions." "setup_gnome_extensions"; then
        to_execute+=("setup_gnome_extensions")
    fi
    if ask_confirmation "Setup virtualization (QEMU/KVM)." "setup_virtualization"; then
        to_execute+=("setup_virtualization")
    fi
}

collect_cleanup() {
    if ask_confirmation "Remove unnecessary packages and hide GNOME apps." "cleanup"; then
        to_execute+=("remove_unnecessary_packages")
        to_execute+=("hide_gnome_menu_apps")
    fi
}

collect_all() {
    # Add all functions
    to_execute=("setup_pacman" "setup_reflector" "setup_chaotic_aur" "install_aur_helper" "setup_locales" "setup_snapper" "setup_graphics_drivers" "setup_terminal" "setup_lizardbyte_repo" "setup_utilities" "setup_flatpak_applications" "setup_development_tools" "setup_gaming" "setup_codecs_and_multimedia" "setup_system_services" "setup_cachyos_kernel" "setup_quiet_boot" "setup_secure_boot" "setup_themes" "setup_gnome_menu_folders" "setup_zswap" "setup_dnsmasq" "setup_earlyoom" "setup_topgrade" "setup_hardware_acceleration_flatpak" "setup_gnome_extensions" "setup_virtualization" "remove_unnecessary_packages" "hide_gnome_menu_apps")
}





# =============================================================================
# SYSTEM CONFIGURATION FUNCTIONS (continued)
# =============================================================================

# Install CachyOS kernels (standard and LTS) with automatic fallback
# Removes generic Arch kernel, keeps Arch LTS as emergency fallback
setup_cachyos_kernel() {
    log_info "Installing CachyOS kernels for improved performance..."

    # Check if Chaotic-AUR is configured
    if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
        log_error "Chaotic-AUR repository required for CachyOS kernels"
        dialog --title "CachyOS Kernel Error" \
               --msgbox "CachyOS kernels require the Chaotic-AUR repository.\n\nPlease enable Chaotic-AUR first." \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
        return 1
    fi

    # Detect boot manager
    local boot_manager
    if [[ -d "/boot/loader" ]]; then
        boot_manager="systemd-boot"
    elif [[ -d "/boot/grub" ]]; then
        boot_manager="grub"
    else
        log_error "No supported boot manager detected (systemd-boot or GRUB)"
        return 1
    fi

    log_info "Detected boot manager: $boot_manager"

    # Install CachyOS kernels
    log_info "Installing CachyOS kernels (standard and LTS)..."
    execute "sudo pacman -S --noconfirm linux-cachyos linux-cachyos-headers linux-cachyos-lts linux-cachyos-lts-headers" "Installing CachyOS kernels"

    # Keep Arch LTS kernel as fallback, remove generic kernel
    log_info "Removing generic Arch kernel, keeping Arch LTS as emergency fallback..."
    if pacman -Qi linux &>/dev/null; then
        execute "sudo pacman -R --noconfirm linux" "Removing generic Arch kernel"
    fi

    # Ensure Arch LTS is installed
    if ! pacman -Qi linux-lts &>/dev/null; then
        execute "sudo pacman -S --noconfirm linux-lts linux-lts-headers" "Installing Arch LTS kernel as fallback"
    fi

    # Update boot manager configuration
    if [[ "$boot_manager" == "systemd-boot" ]]; then
        log_info "Configuring systemd-boot..."
        sudo bootctl update 2>&1 | tee -a "${CONFIG[LOG_FILE]}" || log_warn "Bootctl update skipped (same version)"

        # Set CachyOS as default if entry exists
        if [[ -f "/boot/loader/entries/arch-cachyos.conf" ]] || [[ -f "/boot/loader/entries/*cachyos*.conf" ]]; then
            backup_file "/boot/loader/loader.conf"
            sudo sed -i 's/^default.*/default arch-cachyos.conf/' /boot/loader/loader.conf 2>/dev/null || true
        fi
    elif [[ "$boot_manager" == "grub" ]]; then
        log_info "Updating GRUB configuration..."
        execute "sudo grub-mkconfig -o /boot/grub/grub.cfg" "Regenerating GRUB configuration"
    fi

    log_info "✓ CachyOS kernels installed successfully"
    log_info "Kernel hierarchy: CachyOS (default) → CachyOS LTS → Arch LTS (emergency)"
}

# Setup intelligent boot recovery system
# Automatically shows recovery menu after first failed boot with forced reboot






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

    # Main menu loop for selection
    while true; do
        choice=$(show_main_menu)

        case "$choice" in
            1) collect_system_config ;;
            2) collect_graphics ;;
            3) collect_shell_terminal ;;
            4) collect_applications ;;
            5) collect_development ;;
            6) collect_gaming ;;
            7) collect_multimedia ;;
            8) collect_services ;;
            9) collect_boot ;;
            10) collect_themes ;;
            11) collect_enhancements ;;
            12) collect_cleanup ;;
            13) collect_all ;;
            14|"") break ;;
        esac

        # If functions selected, ask if ready to execute
        if [[ ${#to_execute[@]} -gt 0 ]]; then
            dialog --title "Ready to Execute" \
                   --yesno "Selected ${#to_execute[@]} functions. Proceed with execution?" \
                   ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}
            if [[ $? -eq 0 ]]; then
                break
            fi
        fi
    done

    # Execute selected functions with GUI progress
    if [[ ${#to_execute[@]} -gt 0 ]]; then
        execute_selected_functions
    fi

    # Cleanup
    rm -rf "${CONFIG[TEMP_DIR]}"

    if [[ ${#to_execute[@]} -gt 0 ]]; then
        log_info "ArchPI completed successfully!"

        # Ask for reboot
        dialog --title "Setup Complete" \
               --yesno "Setup completed! Reboot now to apply all changes?" \
               ${CONFIG[DIALOG_HEIGHT]} ${CONFIG[DIALOG_WIDTH]}

        if [[ $? -eq 0 ]]; then
            log_info "Rebooting system..."
            sudo reboot
        fi
    else
        log_info "No functions selected. Exiting."
    fi

    log_info "Post-installation script completed."
}

# Remove unnecessary GNOME packages for a cleaner system
remove_unnecessary_packages() {
    log_info "Removing unnecessary GNOME packages..."

    # List of packages that can be safely removed in most GNOME setups
    local packages_to_remove=(
        "gnome-contacts"
        "gnome-maps"
        "gnome-weather"
        "gnome-clocks"
        "gnome-calendar"
        "totem"
        "gnome-music"
        "gnome-photos"
    )

    # Check which packages are installed and remove them
    local installed_packages=()
    for pkg in "${packages_to_remove[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            installed_packages+=("$pkg")
        fi
    done

    if [[ ${#installed_packages[@]} -gt 0 ]]; then
        log_info "Removing packages: ${installed_packages[*]}"
        execute "sudo pacman -Rns --noconfirm ${installed_packages[*]}" "Removing unnecessary GNOME packages"
    else
        log_info "No unnecessary packages found to remove"
    fi
}

# Hide unused applications from GNOME menu
hide_gnome_menu_apps() {
    log_info "Hiding unused applications from GNOME menu..."

    # Create desktop file overrides to hide applications
    local hide_apps=(
        "org.gnome.Contacts.desktop"
        "org.gnome.Maps.desktop"
        "org.gnome.Weather.desktop"
        "org.gnome.Clocks.desktop"
        "org.gnome.Calendar.desktop"
        "org.gnome.Totem.desktop"
        "org.gnome.Music.desktop"
        "org.gnome.Photos.desktop"
    )

    for app in "${hide_apps[@]}"; do
        if [[ -f "/usr/share/applications/$app" ]]; then
            sudo mkdir -p "/usr/share/applications/hidden"
            sudo mv "/usr/share/applications/$app" "/usr/share/applications/hidden/" 2>/dev/null || true
        fi
    done

    log_info "Unused applications hidden from GNOME menu"
}

execute_selected_functions() {
    local total=${#to_execute[@]}
    local current=0

    echo "Starting execution of selected functions..."
    for func in "${to_execute[@]}"; do
        current=$((current + 1))
        echo "[$current/$total] Executing $func..."

        if declare -f "$func" > /dev/null; then
            $func
            echo "✓ $func completed."
        else
            echo "✗ Function $func not found."
        fi
    done

    echo "All selected functions have been executed. Check full logs at ${CONFIG[LOG_FILE]}"
}

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
    

