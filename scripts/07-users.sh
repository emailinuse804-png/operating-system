#!/bin/bash
###############################################################################
# 07-users.sh - Create user accounts
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Creating user accounts..."

chroot "${ROOTFS_DIR}" bash -c '
    # Set root password
    echo "root:sleekos" | chpasswd

    # Create default user
    useradd -m -s /bin/bash -G sudo,audio,video,plugdev,netdev,bluetooth,cdrom,floppy,disk sleek 2>/dev/null || true
    echo "sleek:sleekos" | chpasswd

    # Allow sudo without password for convenience in live mode
    echo "sleek ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/sleek
    chmod 440 /etc/sudoers.d/sleek

    # Add user to ollama group
    usermod -aG ollama sleek 2>/dev/null || true
'

# ─── Copy skel to user home ────────────────────────────────────────────────
log_info "Setting up user home directory..."
chroot "${ROOTFS_DIR}" bash -c '
    # Ensure skel is applied
    cp -a /etc/skel/. /home/sleek/ 2>/dev/null || true
    chown -R sleek:sleek /home/sleek/

    # Create standard directories
    mkdir -p /home/sleek/{Desktop,Documents,Downloads,Music,Pictures,Videos}
    chown -R sleek:sleek /home/sleek/
'

# ─── Welcome file on Desktop ──────────────────────────────────────────────
cat > "${ROOTFS_DIR}/home/sleek/Desktop/Welcome.txt" << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                Welcome to SleekOS v1.0                       ║
║                    Aurora Edition                             ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║                                                              ║
║  Quick Start:                                                ║
║                                                              ║
║  🌐  Web Browser    - Click the browser icon in the taskbar  ║
║  🧠  SleekAI        - Press Super+A or click the AI icon     ║
║  📁  Files          - Click the folder icon                  ║
║  ⚙️  Settings       - Right-click desktop > Settings         ║
║  💻  Terminal       - Press Super+T or use the terminal icon ║
║                                                              ║
║  Setting up AI:                                              ║
║  1. Open Terminal                                            ║
║  2. Run: ollama pull llama3.2                                ║
║  3. Launch SleekAI from the desktop                          ║
║                                                              ║
║  Default Login:                                              ║
║  User: sleek  |  Password: sleekos                           ║
║                                                              ║
║  Enjoy SleekOS! 🚀                                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
EOF
chroot "${ROOTFS_DIR}" bash -c 'chown sleek:sleek /home/sleek/Desktop/Welcome.txt'

log_success "User accounts configured"
