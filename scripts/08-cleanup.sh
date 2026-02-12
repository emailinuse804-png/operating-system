#!/bin/bash
###############################################################################
# 08-cleanup.sh - Clean up build artifacts and reduce image size
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Cleaning up build..."

# ─── Make custom scripts executable ─────────────────────────────────────────
log_info "Setting permissions..."
chmod +x "${ROOTFS_DIR}/usr/local/bin/"* 2>/dev/null || true
chmod +x "${ROOTFS_DIR}/etc/skel/Desktop/"*.desktop 2>/dev/null || true

# ─── Create start menu local dir ────────────────────────────────────────────
mkdir -p "${ROOTFS_DIR}/usr/local/share/applications"
# Copy the start desktop file if not already there
if [[ -f "${CUSTOM_ROOTFS}/usr/local/share/applications/sleekos-start.desktop" ]]; then
    cp "${CUSTOM_ROOTFS}/usr/local/share/applications/sleekos-start.desktop" \
       "${ROOTFS_DIR}/usr/local/share/applications/" 2>/dev/null || true
fi

# ─── Custom neofetch ASCII art ──────────────────────────────────────────────
log_info "Setting up SleekOS branding..."
mkdir -p "${ROOTFS_DIR}/etc"
cat > "${ROOTFS_DIR}/etc/sleekos-release" << EOF
SleekOS ${SLEEKOS_VERSION} (${SLEEKOS_CODENAME})
Built: $(date -u +"%Y-%m-%d %H:%M UTC")
Architecture: ${ARCH}
Base: Debian ${DEBIAN_SUITE}
EOF

# ─── Cleanup in chroot ─────────────────────────────────────────────────────
log_info "Cleaning package cache and temporary files..."
chroot "${ROOTFS_DIR}" bash -c '
    export DEBIAN_FRONTEND=noninteractive

    # Clean APT cache
    apt-get clean
    apt-get autoremove -y 2>/dev/null || true
    rm -rf /var/lib/apt/lists/*

    # Clean temporary files
    rm -rf /tmp/*
    rm -rf /var/tmp/*

    # Clean logs
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;
    find /var/log -type f -name "*.gz" -delete
    find /var/log -type f -name "*.old" -delete

    # Remove build artifacts
    rm -f /tmp/install-ollama.sh

    # Remove docs to save space (optional)
    # rm -rf /usr/share/doc/*
    # rm -rf /usr/share/man/*

    # Clear bash history
    rm -f /root/.bash_history
    rm -f /home/sleek/.bash_history 2>/dev/null || true

    # Regenerate font cache
    fc-cache -f 2>/dev/null || true
'

# ─── Set proper ownership ──────────────────────────────────────────────────
chroot "${ROOTFS_DIR}" bash -c '
    chown -R sleek:sleek /home/sleek/ 2>/dev/null || true
'

log_success "Cleanup complete"
