#!/bin/bash
###############################################################################
# 01-bootstrap.sh - Create minimal Debian rootfs via debootstrap
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Bootstrapping Debian ${DEBIAN_SUITE} (${ARCH})..."

# ─── Run debootstrap ────────────────────────────────────────────────────────
debootstrap \
    --arch="${ARCH}" \
    --variant=minbase \
    --include=apt,apt-utils,locales,ca-certificates,wget,curl,gnupg \
    "${DEBIAN_SUITE}" \
    "${ROOTFS_DIR}" \
    "${DEBIAN_MIRROR}"

log_success "Debootstrap complete"

# ─── Set up APT sources ────────────────────────────────────────────────────
log_info "Configuring APT sources..."
cp "${CONFIG_DIR}/sources.list" "${ROOTFS_DIR}/etc/apt/sources.list"

# ─── Mount required filesystems ─────────────────────────────────────────────
log_info "Mounting virtual filesystems..."
mount --bind /dev     "${ROOTFS_DIR}/dev"
mount --bind /dev/pts "${ROOTFS_DIR}/dev/pts"
mount -t proc  proc   "${ROOTFS_DIR}/proc"
mount -t sysfs sysfs  "${ROOTFS_DIR}/sys"
mount -t tmpfs tmpfs   "${ROOTFS_DIR}/run"

# ─── Configure locale and timezone ──────────────────────────────────────────
log_info "Configuring locale and timezone..."
chroot "${ROOTFS_DIR}" bash -c '
    export DEBIAN_FRONTEND=noninteractive

    # Locale
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/default/locale

    # Timezone
    ln -sf /usr/share/zoneinfo/UTC /etc/localtime
    echo "UTC" > /etc/timezone
'

# ─── Update package index ──────────────────────────────────────────────────
log_info "Updating APT package index..."
chroot "${ROOTFS_DIR}" bash -c '
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
'

log_success "Bootstrap phase complete"
