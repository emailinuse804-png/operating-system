#!/bin/bash
###############################################################################
# SleekOS Build System
# Creates a bootable x64 ISO with Windows-like UI, Ollama, and GRUB
###############################################################################

set -euo pipefail

# ─── Configuration ──────────────────────────────────────────────────────────
export SLEEKOS_VERSION="1.0"
export SLEEKOS_NAME="SleekOS"
export SLEEKOS_CODENAME="Aurora"
export ARCH="amd64"
export DEBIAN_SUITE="bookworm"
export DEBIAN_MIRROR="http://deb.debian.org/debian"

# ─── Paths ──────────────────────────────────────────────────────────────────
export BUILD_DIR="$(pwd)/build"
export ROOTFS_DIR="${BUILD_DIR}/rootfs"
export ISO_DIR="${BUILD_DIR}/iso"
export OUTPUT_DIR="$(pwd)/output"
export SCRIPTS_DIR="$(pwd)/scripts"
export CONFIG_DIR="$(pwd)/config"
export CUSTOM_ROOTFS="$(pwd)/rootfs"
export GRUB_DIR="$(pwd)/grub"
export ISO_SRC="$(pwd)/iso"

# ─── Colors ─────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Logging ────────────────────────────────────────────────────────────────
log_info()    { echo -e "${CYAN}[INFO]${NC}    $*"; }
log_success() { echo -e "${GREEN}[OK]${NC}      $*"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
log_error()   { echo -e "${RED}[ERROR]${NC}   $*"; }
log_step()    { echo -e "\n${BOLD}${BLUE}══════════════════════════════════════════════════${NC}"; \
                echo -e "${BOLD}${BLUE}  $*${NC}"; \
                echo -e "${BOLD}${BLUE}══════════════════════════════════════════════════${NC}\n"; }

# ─── Helpers ────────────────────────────────────────────────────────────────
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_arch() {
    local host_arch
    host_arch=$(uname -m)
    if [[ "$host_arch" != "x86_64" ]]; then
        log_error "This script must be run on an x86_64 host (detected: $host_arch)"
        exit 1
    fi
}

check_deps() {
    local missing=()
    local deps=(debootstrap xorriso grub-pc-bin grub-efi-amd64-bin mtools squashfs-tools)
    for dep in "${deps[@]}"; do
        if ! dpkg -l "$dep" &>/dev/null; then
            missing+=("$dep")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing build dependencies: ${missing[*]}"
        log_info "Run: sudo make deps"
        exit 1
    fi
}

cleanup_mounts() {
    log_info "Cleaning up mount points..."
    for mp in proc sys dev/pts dev run; do
        umount -lf "${ROOTFS_DIR}/${mp}" 2>/dev/null || true
    done
}

trap cleanup_mounts EXIT

# ─── Install build dependencies ────────────────────────────────────────────
install_deps() {
    log_step "Installing Build Dependencies"
    apt-get update
    apt-get install -y \
        debootstrap \
        xorriso \
        grub-pc-bin \
        grub-efi-amd64-bin \
        grub-common \
        grub2-common \
        mtools \
        squashfs-tools \
        dosfstools \
        isolinux \
        syslinux-common \
        wget \
        curl \
        git \
        sudo
    log_success "Build dependencies installed"
}

# ─── Build Pipeline ────────────────────────────────────────────────────────
run_build() {
    log_step "${SLEEKOS_NAME} v${SLEEKOS_VERSION} Build System"
    echo -e "  Architecture:  ${BOLD}${ARCH}${NC}"
    echo -e "  Base:          ${BOLD}Debian ${DEBIAN_SUITE}${NC}"
    echo -e "  Codename:      ${BOLD}${SLEEKOS_CODENAME}${NC}"
    echo ""

    check_root
    check_arch
    check_deps

    # Clean previous build
    log_info "Cleaning previous build artifacts..."
    rm -rf "${BUILD_DIR}"
    mkdir -p "${BUILD_DIR}" "${ROOTFS_DIR}" "${ISO_DIR}" "${OUTPUT_DIR}"

    # Run build scripts in order
    local scripts=(
        "01-bootstrap.sh"
        "02-configure.sh"
        "03-desktop.sh"
        "04-apps.sh"
        "05-ollama.sh"
        "06-theme.sh"
        "07-users.sh"
        "08-cleanup.sh"
        "09-iso.sh"
    )

    for script in "${scripts[@]}"; do
        local script_path="${SCRIPTS_DIR}/${script}"
        if [[ -f "$script_path" ]]; then
            log_step "Running: ${script}"
            bash "$script_path"
            log_success "Completed: ${script}"
        else
            log_warn "Script not found: ${script_path}"
        fi
    done

    log_step "Build Complete!"
    local iso_path="${OUTPUT_DIR}/sleekos-${SLEEKOS_VERSION}-${ARCH}.iso"
    if [[ -f "$iso_path" ]]; then
        local iso_size
        iso_size=$(du -h "$iso_path" | cut -f1)
        echo -e "  ${GREEN}ISO:${NC}  ${iso_path}"
        echo -e "  ${GREEN}Size:${NC} ${iso_size}"
        echo ""
        echo -e "  To run in VirtualBox:"
        echo -e "  1. Create a new VM (Linux / Debian 64-bit)"
        echo -e "  2. Assign 4 GB RAM and 20 GB disk"
        echo -e "  3. Mount the ISO as CD/DVD"
        echo -e "  4. Boot and enjoy ${SLEEKOS_NAME}!"
    else
        log_error "ISO was not generated!"
        exit 1
    fi
}

# ─── Clean ──────────────────────────────────────────────────────────────────
run_clean() {
    log_step "Cleaning Build Artifacts"
    cleanup_mounts
    rm -rf "${BUILD_DIR}" "${OUTPUT_DIR}"
    log_success "Clean complete"
}

# ─── Main ───────────────────────────────────────────────────────────────────
case "${1:-build}" in
    deps)    install_deps ;;
    build)   run_build ;;
    clean)   run_clean ;;
    *)       echo "Usage: $0 {deps|build|clean}"; exit 1 ;;
esac
