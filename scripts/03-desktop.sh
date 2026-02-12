#!/bin/bash
###############################################################################
# 03-desktop.sh - Install desktop environment (Openbox + compositing stack)
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Installing desktop environment..."

# ─── Read package list ──────────────────────────────────────────────────────
PACKAGES=""
while IFS= read -r line; do
    # Skip comments and empty lines
    line=$(echo "$line" | sed 's/#.*//' | xargs)
    [[ -z "$line" ]] && continue
    PACKAGES="${PACKAGES} ${line}"
done < "${CONFIG_DIR}/packages.list"

# ─── Install packages in chroot ────────────────────────────────────────────
log_info "Installing packages (this may take a while)..."
chroot "${ROOTFS_DIR}" bash -c "
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get install -y --no-install-recommends ${PACKAGES}
    apt-get install -y dbus-x11
"

# ─── Enable services ───────────────────────────────────────────────────────
log_info "Enabling system services..."
chroot "${ROOTFS_DIR}" bash -c '
    systemctl enable lightdm
    systemctl enable NetworkManager
    systemctl enable dbus
'

# ─── Configure LightDM ─────────────────────────────────────────────────────
log_info "Configuring LightDM display manager..."
cat > "${ROOTFS_DIR}/etc/lightdm/lightdm.conf" << 'EOF'
[LightDM]
logind-check-graphical=false

[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=sleekos
autologin-user=sleek
autologin-user-timeout=0
greeter-hide-users=false

[VNCServer]
enabled=false
EOF

cat > "${ROOTFS_DIR}/etc/lightdm/lightdm-gtk-greeter.conf" << 'EOF'
[greeter]
theme-name=SleekOS
icon-theme-name=Papirus-Dark
font-name=Noto Sans 11
background=#0a0a14
user-background=false
xft-antialias=true
xft-dpi=96
xft-hintstyle=slight
xft-rgba=rgb
indicators=~host;~spacer;~clock;~spacer;~session;~power
clock-format=%A, %B %d  %I:%M %p
position=30%,center 50%,center
panel-position=top
EOF

# ─── Create session file ───────────────────────────────────────────────────
log_info "Creating SleekOS desktop session..."
mkdir -p "${ROOTFS_DIR}/usr/share/xsessions"
cat > "${ROOTFS_DIR}/usr/share/xsessions/sleekos.desktop" << 'EOF'
[Desktop Entry]
Name=SleekOS
Comment=SleekOS Desktop Environment
Exec=/usr/local/bin/sleekos-session
TryExec=/usr/local/bin/sleekos-session
Type=Application
DesktopNames=SleekOS
EOF

# ─── Session startup script ────────────────────────────────────────────────
cat > "${ROOTFS_DIR}/usr/local/bin/sleekos-session" << 'SESSIONEOF'
#!/bin/bash
###############################################################################
# SleekOS Desktop Session
###############################################################################

# ─── Environment ────────────────────────────────────────────────────────────
export XDG_CURRENT_DESKTOP="SleekOS"
export XDG_SESSION_DESKTOP="SleekOS"
export XDG_CONFIG_HOME="${HOME}/.config"
export XDG_DATA_HOME="${HOME}/.local/share"
export QT_QPA_PLATFORMTHEME="gtk2"
export GTK_THEME="SleekOS"

# ─── DPI Scaling ────────────────────────────────────────────────────────────
xrdb -merge <<< "Xft.dpi: 96"
xrdb -merge <<< "Xft.antialias: 1"
xrdb -merge <<< "Xft.hinting: 1"
xrdb -merge <<< "Xft.hintstyle: hintslight"
xrdb -merge <<< "Xft.rgba: rgb"

# ─── Set wallpaper ──────────────────────────────────────────────────────────
if command -v nitrogen &>/dev/null; then
    nitrogen --restore &
fi

# ─── Start compositor ──────────────────────────────────────────────────────
if command -v picom &>/dev/null; then
    picom --config "${XDG_CONFIG_HOME}/picom/picom.conf" -b &
fi

# ─── Start taskbar ─────────────────────────────────────────────────────────
if command -v tint2 &>/dev/null; then
    tint2 &
fi

# ─── Start notification daemon ─────────────────────────────────────────────
if command -v dunst &>/dev/null; then
    dunst &
fi

# ─── Start polkit agent ────────────────────────────────────────────────────
if command -v lxpolkit &>/dev/null; then
    lxpolkit &
fi

# ─── Start network tray ────────────────────────────────────────────────────
if command -v nm-tray &>/dev/null; then
    nm-tray &
fi

# ─── Start power manager ───────────────────────────────────────────────────
if command -v xfce4-power-manager &>/dev/null; then
    xfce4-power-manager &
fi

# ─── Desktop icons (PCManFM) ───────────────────────────────────────────────
if command -v pcmanfm &>/dev/null; then
    pcmanfm --desktop &
fi

# ─── Start Openbox window manager ──────────────────────────────────────────
exec openbox --config-file "${XDG_CONFIG_HOME}/openbox/rc.xml"
SESSIONEOF
chmod +x "${ROOTFS_DIR}/usr/local/bin/sleekos-session"

log_success "Desktop environment installed"
