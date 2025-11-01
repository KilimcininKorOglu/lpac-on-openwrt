#!/bin/bash

###############################################################################
# OpenWRT lpac Build Script
# Automatically builds lpac package for OpenWRT
# Usage: ./build-lpac-openwrt.sh [VERSION] [TARGET] [SUBTARGET] [THREADS]
# Example: ./build-lpac-openwrt.sh 24.10.4 x86 64 8
###############################################################################

set -e  # Exit on error

# Default Configuration
DEFAULT_VERSION="24.10.4"
DEFAULT_TARGET="x86"
DEFAULT_SUBTARGET="64"
DEFAULT_THREADS=$(nproc)

# Parse command line arguments
OPENWRT_VERSION="${1:-$DEFAULT_VERSION}"
OPENWRT_TARGET="${2:-$DEFAULT_TARGET}"
OPENWRT_SUBTARGET="${3:-$DEFAULT_SUBTARGET}"
THREADS="${4:-$DEFAULT_THREADS}"

# Other configurations
BUILD_DIR="${HOME}/openwrt-build"
OPENWRT_DIR="${BUILD_DIR}/openwrt"
LPAC_REPO_URL="https://github.com/KilimcininKorOglu/lpac-on-openwrt.git"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

###############################################################################
# Helper Functions
###############################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_dependencies() {
    log_info "Checking required dependencies..."

    local deps=(
        "git" "build-essential" "libncurses5-dev" "gawk" "gettext"
        "unzip" "file" "libssl-dev" "wget" "python3" "rsync"
        "python3-distutils" "zlib1g-dev" "libelf-dev"
    )

    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! dpkg -l | grep -qw "$dep" 2>/dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_warn "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing missing dependencies..."
        sudo apt-get update
        sudo apt-get install -y "${missing_deps[@]}"
    else
        log_info "All dependencies are installed"
    fi
}

download_openwrt() {
    log_info "Downloading OpenWRT ${OPENWRT_VERSION}..."

    if [ -d "${OPENWRT_DIR}" ]; then
        log_warn "OpenWRT directory already exists: ${OPENWRT_DIR}"
        read -p "Remove and re-download? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${OPENWRT_DIR}"
        else
            log_info "Using existing OpenWRT directory"
            return 0
        fi
    fi

    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"

    # Clone OpenWRT repository
    git clone https://git.openwrt.org/openwrt/openwrt.git
    cd openwrt

    # Checkout specific version
    git checkout "v${OPENWRT_VERSION}" || {
        log_error "Failed to checkout version ${OPENWRT_VERSION}"
        log_info "Available tags:"
        git tag | grep "^v${OPENWRT_VERSION%.*}" | tail -5
        exit 1
    }

    log_info "OpenWRT ${OPENWRT_VERSION} downloaded successfully"
}

setup_feeds() {
    log_info "Setting up feeds..."
    cd "${OPENWRT_DIR}"

    # Update feeds
    ./scripts/feeds update -a
    ./scripts/feeds install -a

    log_info "Feeds updated and installed"
}

integrate_lpac() {
    log_info "Integrating lpac package..."

    local lpac_dir="${OPENWRT_DIR}/package/utils/lpac"

    if [ -d "${lpac_dir}" ]; then
        log_warn "lpac directory already exists, removing..."
        rm -rf "${lpac_dir}"
    fi

    mkdir -p "${OPENWRT_DIR}/package/utils"

    # Clone lpac-on-openwrt repository
    if [ -n "${LPAC_REPO_URL}" ] && [[ ! "${LPAC_REPO_URL}" =~ YOUR_USERNAME ]]; then
        log_info "Cloning lpac from: ${LPAC_REPO_URL}"
        git clone "${LPAC_REPO_URL}" "${lpac_dir}"
    else
        # Copy from current directory if script is run from lpac repo
        if [ -f "$(dirname "$0")/Makefile" ]; then
            log_info "Copying lpac from current directory..."
            cp -r "$(dirname "$0")" "${lpac_dir}"
            rm -rf "${lpac_dir}/.git"  # Remove .git to avoid conflicts
        else
            log_error "Please set LPAC_REPO_URL in the script or run from lpac repository"
            exit 1
        fi
    fi

    log_info "lpac package integrated"
}

configure_build() {
    log_info "Configuring build for ${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}..."
    cd "${OPENWRT_DIR}"

    # Create custom config
    cat > .config <<EOF
CONFIG_TARGET_${OPENWRT_TARGET}=y
CONFIG_TARGET_${OPENWRT_TARGET}_${OPENWRT_SUBTARGET}=y
CONFIG_PACKAGE_lpac=y
CONFIG_PACKAGE_libopenssl=y
CONFIG_PACKAGE_pcscd=y
CONFIG_PACKAGE_libpcsclite=y
CONFIG_PACKAGE_libcurl=y
EOF

    # Expand config
    make defconfig

    log_info "Build configured"
}

build_toolchain() {
    log_info "Building toolchain (this may take a while)..."
    cd "${OPENWRT_DIR}"

    make -j${THREADS} toolchain/install V=s || {
        log_error "Toolchain build failed"
        exit 1
    }

    log_info "Toolchain built successfully"
}

build_lpac() {
    log_info "Building lpac package..."
    cd "${OPENWRT_DIR}"

    # Clean previous builds
    make package/lpac/clean V=s

    # Build lpac
    make package/lpac/compile -j${THREADS} V=s || {
        log_error "lpac build failed"
        log_info "Check build log for details"
        exit 1
    }

    log_info "lpac built successfully"
}

find_package() {
    log_info "Locating built package..."
    cd "${OPENWRT_DIR}"

    local ipk_file=$(find bin/packages -name "lpac*.ipk" 2>/dev/null | head -1)

    if [ -z "${ipk_file}" ]; then
        log_error "Could not find lpac .ipk package"
        exit 1
    fi

    log_info "Package built: ${ipk_file}"
    log_info "Package size: $(du -h "${ipk_file}" | cut -f1)"

    # Copy to easy access location
    cp "${ipk_file}" "${BUILD_DIR}/lpac_${OPENWRT_VERSION}_x86_64.ipk"
    log_info "Package copied to: ${BUILD_DIR}/lpac_${OPENWRT_VERSION}_x86_64.ipk"
}

show_summary() {
    echo ""
    log_info "=== Build Summary ==="
    log_info "OpenWRT Version: ${OPENWRT_VERSION}"
    log_info "Target: ${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}"
    log_info "Build Directory: ${BUILD_DIR}"
    log_info "Package Location: ${BUILD_DIR}/lpac_${OPENWRT_VERSION}_x86_64.ipk"
    echo ""
    log_info "To install on your OpenWRT device:"
    echo "  1. Copy the .ipk file to your router"
    echo "  2. Run: opkg install lpac_${OPENWRT_VERSION}_x86_64.ipk"
    echo ""
}

###############################################################################
# Main Script
###############################################################################

show_usage() {
    cat << EOF
Usage: $0 [OPTIONS] [VERSION] [TARGET] [SUBTARGET] [THREADS]

Automatically builds lpac package for OpenWRT.

Arguments:
    VERSION     OpenWRT version (default: ${DEFAULT_VERSION})
    TARGET      Target architecture (default: ${DEFAULT_TARGET})
    SUBTARGET   Target sub-architecture (default: ${DEFAULT_SUBTARGET})
    THREADS     Number of parallel jobs (default: ${DEFAULT_THREADS})

Options:
    -h, --help              Show this help message
    -l, --list-targets      List common target combinations
    -c, --clean             Clean build directory before building
    -s, --skip-toolchain    Skip toolchain build (use existing)

Examples:
    # Build with defaults (24.10.4, x86/64)
    $0

    # Build specific version for x86
    $0 24.10.4 x86 64

    # Build for Raspberry Pi 4
    $0 24.10.4 bcm27xx bcm2711

    # Build with 8 threads
    $0 24.10.4 x86 64 8

    # Clean build
    $0 --clean

Common Targets:
    x86 64              - x86_64 PC/Server
    bcm27xx bcm2711     - Raspberry Pi 4
    bcm27xx bcm2708     - Raspberry Pi 1
    armsr armv8         - ARM 64-bit generic
    ramips mt7621       - MediaTek MT7621 routers
    ath79 generic       - Qualcomm Atheros AR71xx/AR724x/AR913x

EOF
}

list_targets() {
    cat << EOF
Common OpenWRT Target Combinations:

x86:
    x86/64              - 64-bit PC (AMD64/Intel 64)
    x86/generic         - 32-bit PC (i386)
    x86/geode           - AMD Geode based systems

Raspberry Pi:
    bcm27xx/bcm2708     - Raspberry Pi 1
    bcm27xx/bcm2709     - Raspberry Pi 2
    bcm27xx/bcm2710     - Raspberry Pi 3
    bcm27xx/bcm2711     - Raspberry Pi 4

ARM:
    armsr/armv8         - ARM 64-bit generic
    armsr/armv7         - ARM 32-bit generic
    bcm47xx/generic     - Broadcom BCM47xx/53xx (ARM)

MediaTek:
    ramips/mt7620       - MediaTek MT7620
    ramips/mt7621       - MediaTek MT7621
    ramips/mt76x8       - MediaTek MT76x8

Qualcomm:
    ath79/generic       - Qualcomm Atheros AR71xx/AR724x/AR913x
    ath79/nand          - Qualcomm Atheros with NAND flash
    ipq40xx/generic     - Qualcomm IPQ40xx

Marvell:
    mvebu/cortexa9      - Marvell Armada 370/XP/38x
    mvebu/cortexa72     - Marvell Armada 7K/8K

For full list, visit: https://openwrt.org/toh/views/toh_available_16128

EOF
}

main() {
    # Parse options
    CLEAN_BUILD=false
    SKIP_TOOLCHAIN=false

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -l|--list-targets)
                list_targets
                exit 0
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -s|--skip-toolchain)
                SKIP_TOOLCHAIN=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
            *)
                break
                ;;
        esac
    done

    # Re-parse positional arguments after options
    if [ $# -ge 1 ]; then OPENWRT_VERSION="$1"; fi
    if [ $# -ge 2 ]; then OPENWRT_TARGET="$2"; fi
    if [ $# -ge 3 ]; then OPENWRT_SUBTARGET="$3"; fi
    if [ $# -ge 4 ]; then THREADS="$4"; fi

    log_info "Starting OpenWRT lpac build process..."
    log_info "Version: ${OPENWRT_VERSION}"
    log_info "Target: ${OPENWRT_TARGET}/${OPENWRT_SUBTARGET}"
    log_info "Threads: ${THREADS}"
    echo ""

    # Clean if requested
    if [ "$CLEAN_BUILD" = true ]; then
        log_warn "Cleaning build directory: ${BUILD_DIR}"
        rm -rf "${BUILD_DIR}"
    fi

    # Check dependencies
    check_dependencies

    # Download OpenWRT
    download_openwrt

    # Setup feeds
    setup_feeds

    # Integrate lpac
    integrate_lpac

    # Configure build
    configure_build

    # Build toolchain (unless skipped)
    if [ "$SKIP_TOOLCHAIN" = false ]; then
        build_toolchain
    else
        log_info "Skipping toolchain build (using existing)"
    fi

    # Build lpac
    build_lpac

    # Find and show package
    find_package

    # Show summary
    show_summary

    log_info "Build completed successfully!"
}

# Run main function
main "$@"
