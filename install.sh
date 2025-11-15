#!/bin/bash
#
# Arch Linux Post-Installation Script - Quick Install
# Direct installation from GitHub using curl | bash
#
# This script clones the arch-linux-pi repository
# and runs the main archPI script automatically
#

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on Arch Linux
check_arch_linux() {
    if ! grep -q "Arch Linux" /etc/os-release 2>/dev/null; then
        print_warn "This script was designed for Arch Linux. Continue anyway? (y/N)"
        read -r -p "" response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            print_info "Installation cancelled."
            exit 0
        fi
    fi
}

# Check for required tools
check_dependencies() {
    local missing_tools=()

    for tool in git sudo curl; do
        if ! command -v "$tool" &>/dev/null; then
            missing_tools+=("$tool")
        fi
    done

    if [[ ${#missing_tools[@]} -ne 0 ]]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install them with: sudo pacman -S ${missing_tools[*]}"
        exit 1
    fi
}

# Main installation function
main() {
    print_info "🚀 Arch Linux Post-Installation Script Quick Install"
    print_info "================================================="

    # Run checks
    check_arch_linux
    check_dependencies

    # Check internet connectivity
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        print_error "No internet connection detected. Please check your network."
        exit 1
    fi

    print_info "⏳ Cloning Arch Linux PI repository..."

    # Clone the repository
    if ! git clone https://github.com/EmanuProds/arch-linux-pi.git; then
        print_error "Failed to clone repository. Please check your internet connection."
        exit 1
    fi

    print_info "📁 Entering repository directory..."
    cd arch-linux-pi || {
        print_error "Failed to enter repository directory"
        exit 1
    }

    print_info "🔧 Making script executable..."
    chmod +x archPI

    print_info "✅ Installation complete!"
    print_info "🎯 Starting ArchPI Post-Installation Script..."
    print_info ""

    # Execute the main script
    exec ./archPI
}

# Run main function
main "$@"
