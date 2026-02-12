#!/bin/bash
###############################################################################
# 02-configure.sh - System configuration (hostname, fstab, networking)
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Configuring system..."

# ─── Hostname ───────────────────────────────────────────────────────────────
HOSTNAME=$(cat "${CONFIG_DIR}/hostname" | tr -d '[:space:]')
echo "${HOSTNAME}" > "${ROOTFS_DIR}/etc/hostname"
cat > "${ROOTFS_DIR}/etc/hosts" << EOF
127.0.0.1   localhost
127.0.1.1   ${HOSTNAME}

::1         localhost ip6-localhost ip6-loopback
ff02::1     ip6-allnodes
ff02::2     ip6-allrouters
EOF

# ─── OS Release ─────────────────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/etc/os-release" << EOF
PRETTY_NAME="${SLEEKOS_NAME} ${SLEEKOS_VERSION} (${SLEEKOS_CODENAME})"
NAME="${SLEEKOS_NAME}"
VERSION="${SLEEKOS_VERSION}"
VERSION_CODENAME="${SLEEKOS_CODENAME}"
ID=sleekos
ID_LIKE=debian
HOME_URL="https://sleekos.dev"
SUPPORT_URL="https://sleekos.dev/support"
BUG_REPORT_URL="https://sleekos.dev/bugs"
EOF

# ─── LSB Release ────────────────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/etc/lsb-release" << EOF
DISTRIB_ID=${SLEEKOS_NAME}
DISTRIB_RELEASE=${SLEEKOS_VERSION}
DISTRIB_CODENAME=${SLEEKOS_CODENAME}
DISTRIB_DESCRIPTION="${SLEEKOS_NAME} ${SLEEKOS_VERSION} (${SLEEKOS_CODENAME})"
EOF

# ─── Fstab (for live system) ────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/etc/fstab" << 'EOF'
# SleekOS fstab - populated by installer for disk installations
# Live mode uses overlay filesystem
tmpfs   /tmp    tmpfs   defaults,noatime,nosuid,nodev   0 0
EOF

# ─── Networking ─────────────────────────────────────────────────────────────
log_info "Configuring NetworkManager..."
mkdir -p "${ROOTFS_DIR}/etc/NetworkManager/conf.d"
cat > "${ROOTFS_DIR}/etc/NetworkManager/conf.d/00-sleekos.conf" << 'EOF'
[main]
plugins=ifupdown,keyfile
dns=default

[ifupdown]
managed=true

[device]
wifi.scan-rand-mac-address=no
EOF

# ─── Kernel modules ────────────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/etc/modules" << 'EOF'
# VirtualBox guest modules
vboxguest
vboxsf
vboxvideo
EOF

# ─── Sysctl tweaks ─────────────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/etc/sysctl.d/99-sleekos.conf" << 'EOF'
# SleekOS Performance Tuning
vm.swappiness=10
vm.vfs_cache_pressure=50
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
fs.inotify.max_user_watches=524288
EOF

# ─── Console & keyboard ────────────────────────────────────────────────────
mkdir -p "${ROOTFS_DIR}/etc/default"
cat > "${ROOTFS_DIR}/etc/default/keyboard" << 'EOF'
XKBMODEL="pc105"
XKBLAYOUT="us"
XKBVARIANT=""
XKBOPTIONS=""
BACKSPACE="guess"
EOF

log_success "System configuration complete"
