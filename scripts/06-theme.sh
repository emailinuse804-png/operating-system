#!/bin/bash
###############################################################################
# 06-theme.sh - Apply SleekOS Windows-like theme and UI
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Applying SleekOS theme..."

# ─── Copy custom rootfs overlay ─────────────────────────────────────────────
log_info "Applying rootfs overlay..."
cp -a "${CUSTOM_ROOTFS}/"* "${ROOTFS_DIR}/" 2>/dev/null || true

# ─── GTK3 Theme (SleekOS - Windows 11 inspired) ─────────────────────────────
log_info "Creating GTK3 theme..."
mkdir -p "${ROOTFS_DIR}/usr/share/themes/SleekOS/gtk-3.0"
cat > "${ROOTFS_DIR}/usr/share/themes/SleekOS/gtk-3.0/gtk.css" << 'GTKCSS'
/*
 * SleekOS GTK3 Theme
 * A modern dark theme inspired by Windows 11
 */

/* ─── Color Definitions ────────────────────────────────────────────────── */
@define-color bg_color #1e1e2e;
@define-color fg_color #cdd6f4;
@define-color base_color #181825;
@define-color text_color #cdd6f4;
@define-color selected_bg_color #89b4fa;
@define-color selected_fg_color #1e1e2e;
@define-color tooltip_bg_color #313244;
@define-color tooltip_fg_color #cdd6f4;
@define-color titlebar_bg #11111b;
@define-color titlebar_fg #cdd6f4;
@define-color border_color #45475a;
@define-color hover_color #313244;
@define-color active_color #45475a;
@define-color insensitive_bg #1e1e2e;
@define-color insensitive_fg #585b70;
@define-color sidebar_bg #181825;
@define-color accent_color #89b4fa;
@define-color error_color #f38ba8;
@define-color warning_color #fab387;
@define-color success_color #a6e3a1;
@define-color link_color #89dceb;
@define-color surface0 #313244;
@define-color surface1 #45475a;
@define-color surface2 #585b70;

/* ─── Global ───────────────────────────────────────────────────────────── */
* {
    -gtk-icon-style: regular;
    outline-color: alpha(@accent_color, 0.3);
    outline-offset: -3px;
    outline-width: 2px;
}

/* ─── Windows ──────────────────────────────────────────────────────────── */
window {
    background-color: @bg_color;
    color: @fg_color;
}

window.background {
    background-color: @bg_color;
}

/* ─── Header Bars (Title Bars) ─────────────────────────────────────────── */
headerbar,
.titlebar {
    background-color: @titlebar_bg;
    color: @titlebar_fg;
    border-bottom: 1px solid @border_color;
    padding: 4px 8px;
    min-height: 38px;
    border-radius: 12px 12px 0 0;
}

headerbar .title,
.titlebar .title {
    font-weight: bold;
    font-size: 13px;
}

headerbar button,
.titlebar button {
    background: transparent;
    border: none;
    border-radius: 6px;
    padding: 4px 8px;
    color: @titlebar_fg;
    min-height: 28px;
    min-width: 28px;
}

headerbar button:hover,
.titlebar button:hover {
    background-color: @hover_color;
}

/* Window close button - red on hover like Windows */
headerbar button.close:hover,
.titlebar button.close:hover {
    background-color: #e81123;
    color: white;
}

/* ─── Buttons ──────────────────────────────────────────────────────────── */
button {
    background-color: @surface0;
    color: @fg_color;
    border: 1px solid @border_color;
    border-radius: 8px;
    padding: 6px 16px;
    min-height: 32px;
    transition: all 200ms ease;
}

button:hover {
    background-color: @hover_color;
    border-color: @surface2;
}

button:active {
    background-color: @active_color;
}

button:checked {
    background-color: @accent_color;
    color: @selected_fg_color;
    border-color: @accent_color;
}

button.suggested-action {
    background-color: @accent_color;
    color: @selected_fg_color;
    border-color: @accent_color;
}

button.suggested-action:hover {
    background-color: shade(@accent_color, 1.1);
}

button.destructive-action {
    background-color: @error_color;
    color: @selected_fg_color;
    border-color: @error_color;
}

/* ─── Entries (Text Fields) ────────────────────────────────────────────── */
entry {
    background-color: @base_color;
    color: @text_color;
    border: 1px solid @border_color;
    border-radius: 8px;
    padding: 8px 12px;
    min-height: 34px;
    transition: border-color 200ms ease;
    caret-color: @accent_color;
}

entry:focus {
    border-color: @accent_color;
    box-shadow: 0 0 0 2px alpha(@accent_color, 0.2);
}

/* ─── Scrollbars ───────────────────────────────────────────────────────── */
scrollbar {
    background: transparent;
}

scrollbar slider {
    background-color: @surface1;
    border-radius: 99px;
    min-width: 6px;
    min-height: 6px;
    margin: 2px;
    transition: all 200ms ease;
}

scrollbar slider:hover {
    background-color: @surface2;
    min-width: 10px;
}

/* ─── Menus & Popovers ────────────────────────────────────────────────── */
menu,
.menu,
popover,
.popover {
    background-color: @surface0;
    color: @fg_color;
    border: 1px solid @border_color;
    border-radius: 12px;
    padding: 6px;
    box-shadow: 0 8px 32px rgba(0,0,0,0.4);
}

menu menuitem,
.menu menuitem {
    border-radius: 6px;
    padding: 6px 12px;
    min-height: 28px;
}

menu menuitem:hover,
.menu menuitem:hover {
    background-color: @hover_color;
}

/* ─── Sidebar / List ───────────────────────────────────────────────────── */
.sidebar,
placessidebar {
    background-color: @sidebar_bg;
    border-right: 1px solid @border_color;
}

.sidebar row,
placessidebar row {
    border-radius: 8px;
    margin: 2px 6px;
    padding: 4px 8px;
}

.sidebar row:selected,
placessidebar row:selected {
    background-color: alpha(@accent_color, 0.2);
    color: @accent_color;
}

/* ─── Notebooks (Tabs) ─────────────────────────────────────────────────── */
notebook {
    background-color: @bg_color;
}

notebook header tab {
    background-color: transparent;
    border: none;
    border-radius: 8px 8px 0 0;
    padding: 6px 16px;
    color: @insensitive_fg;
}

notebook header tab:checked {
    background-color: @bg_color;
    color: @fg_color;
    border-bottom: 2px solid @accent_color;
}

/* ─── Tooltips ─────────────────────────────────────────────────────────── */
tooltip,
.tooltip {
    background-color: @tooltip_bg_color;
    color: @tooltip_fg_color;
    border: 1px solid @border_color;
    border-radius: 8px;
    padding: 6px 10px;
}

/* ─── Progress Bars ────────────────────────────────────────────────────── */
progressbar trough {
    background-color: @surface0;
    border-radius: 99px;
    min-height: 6px;
}

progressbar progress {
    background-color: @accent_color;
    border-radius: 99px;
    min-height: 6px;
}

/* ─── Switches ─────────────────────────────────────────────────────────── */
switch {
    background-color: @surface1;
    border-radius: 99px;
    min-width: 48px;
    min-height: 24px;
}

switch:checked {
    background-color: @accent_color;
}

switch slider {
    background-color: white;
    border-radius: 50%;
    min-width: 20px;
    min-height: 20px;
    margin: 2px;
}

/* ─── Check & Radio Buttons ────────────────────────────────────────────── */
check,
radio {
    background-color: @base_color;
    border: 2px solid @surface2;
    min-width: 20px;
    min-height: 20px;
}

check {
    border-radius: 4px;
}

radio {
    border-radius: 50%;
}

check:checked,
radio:checked {
    background-color: @accent_color;
    border-color: @accent_color;
    color: white;
}

/* ─── Tree / List Views ────────────────────────────────────────────────── */
treeview {
    background-color: @base_color;
    color: @text_color;
}

treeview:selected {
    background-color: alpha(@accent_color, 0.2);
    color: @fg_color;
}

treeview header button {
    background-color: @surface0;
    border-bottom: 1px solid @border_color;
    border-radius: 0;
}

/* ─── Selection ────────────────────────────────────────────────────────── */
*:selected {
    background-color: @selected_bg_color;
    color: @selected_fg_color;
}

/* ─── Links ────────────────────────────────────────────────────────────── */
*:link,
button:link {
    color: @link_color;
}

/* ─── Status Bar ───────────────────────────────────────────────────────── */
statusbar {
    background-color: @titlebar_bg;
    color: @insensitive_fg;
    border-top: 1px solid @border_color;
    padding: 2px 8px;
}

/* ─── Dialog ───────────────────────────────────────────────────────────── */
dialog .dialog-vbox {
    background-color: @bg_color;
}

messagedialog .titlebar {
    background-color: @bg_color;
}

/* ─── File Chooser ─────────────────────────────────────────────────────── */
filechooser placessidebar {
    background-color: @sidebar_bg;
}

/* ─── Calendar ─────────────────────────────────────────────────────────── */
calendar {
    background-color: @surface0;
    color: @fg_color;
    border-radius: 12px;
    padding: 8px;
}

calendar:selected {
    background-color: @accent_color;
    color: @selected_fg_color;
    border-radius: 50%;
}
GTKCSS

# Also create index.theme for the theme
cat > "${ROOTFS_DIR}/usr/share/themes/SleekOS/index.theme" << 'EOF'
[Desktop Entry]
Type=X-GNOME-Metatheme
Name=SleekOS
Comment=SleekOS Dark Theme - Windows 11 Inspired
Encoding=UTF-8

[X-GNOME-Metatheme]
GtkTheme=SleekOS
MetacityTheme=SleekOS
IconTheme=Papirus-Dark
CursorTheme=default
ButtonLayout=menu:minimize,maximize,close
EOF

# ─── Openbox Theme (Window Decorations) ─────────────────────────────────────
log_info "Creating Openbox window decoration theme..."
mkdir -p "${ROOTFS_DIR}/usr/share/themes/SleekOS/openbox-3"
cat > "${ROOTFS_DIR}/usr/share/themes/SleekOS/openbox-3/themerc" << 'EOF'
# SleekOS Openbox Theme - Windows 11 Inspired

# ─── Title Bar ──────────────────────────────────────────────────────────
window.active.title.bg:             flat solid
window.active.title.bg.color:       #11111b
window.inactive.title.bg:           flat solid
window.inactive.title.bg.color:     #181825

# Title text
window.active.label.bg:             parentrelative
window.active.label.text.color:     #cdd6f4
window.active.label.text.font:      shadow=n
window.inactive.label.bg:           parentrelative
window.inactive.label.text.color:   #585b70
window.inactive.label.text.font:    shadow=n

padding.width:                      8
padding.height:                     6
window.label.text.justify:          left

# ─── Window Borders ─────────────────────────────────────────────────────
border.width:                       1
window.active.border.color:         #45475a
window.inactive.border.color:       #313244
window.active.client.color:         #1e1e2e
window.inactive.client.color:       #181825

# ─── Title Bar Buttons ──────────────────────────────────────────────────
window.active.button.unpressed.bg:          flat solid
window.active.button.unpressed.bg.color:    #11111b
window.active.button.unpressed.image.color: #cdd6f4

window.active.button.hover.bg:              flat solid
window.active.button.hover.bg.color:        #313244
window.active.button.hover.image.color:     #ffffff

window.active.button.pressed.bg:            flat solid
window.active.button.pressed.bg.color:      #45475a
window.active.button.pressed.image.color:   #ffffff

# Close button - red on hover (Windows style)
window.active.button.close.hover.bg:            flat solid
window.active.button.close.hover.bg.color:       #e81123
window.active.button.close.hover.image.color:    #ffffff

window.active.button.close.pressed.bg:           flat solid
window.active.button.close.pressed.bg.color:     #c42b1c
window.active.button.close.pressed.image.color:  #ffffff

# Inactive buttons
window.inactive.button.unpressed.bg:        flat solid
window.inactive.button.unpressed.bg.color:  #181825
window.inactive.button.unpressed.image.color: #585b70

window.inactive.button.hover.bg:            flat solid
window.inactive.button.hover.bg.color:      #313244
window.inactive.button.hover.image.color:   #a6adc8

# ─── Menu ────────────────────────────────────────────────────────────────
menu.border.width:                  1
menu.border.color:                  #45475a
menu.overlap.x:                     0
menu.overlap.y:                     0

menu.title.bg:                      flat solid
menu.title.bg.color:                #1e1e2e
menu.title.text.color:              #cdd6f4
menu.title.text.justify:            center

menu.items.bg:                      flat solid
menu.items.bg.color:                #1e1e2e
menu.items.text.color:              #cdd6f4
menu.items.disabled.text.color:     #585b70

menu.items.active.bg:               flat solid
menu.items.active.bg.color:         #313244
menu.items.active.text.color:       #89b4fa

menu.separator.color:               #45475a
menu.separator.width:               1
menu.separator.padding.width:       8
menu.separator.padding.height:      4

# ─── OSD (On-Screen Display) ────────────────────────────────────────────
osd.bg:                             flat solid
osd.bg.color:                       #1e1e2e
osd.border.color:                   #45475a
osd.border.width:                   1
osd.label.bg:                       parentrelative
osd.label.text.color:               #cdd6f4

osd.hilight.bg:                     flat solid
osd.hilight.bg.color:               #89b4fa
osd.unhilight.bg:                   flat solid
osd.unhilight.bg.color:             #313244

# ─── Corner Radius ──────────────────────────────────────────────────────
window.active.border.radius:        12
window.inactive.border.radius:      12
EOF

# ─── Generate wallpaper (SVG) ──────────────────────────────────────────────
log_info "Creating default wallpaper..."
cat > "${ROOTFS_DIR}/usr/share/sleekos/wallpapers/default.svg" << 'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" width="3840" height="2160" viewBox="0 0 3840 2160">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#0a0a1a;stop-opacity:1" />
      <stop offset="50%" style="stop-color:#0f1628;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#0a0a1a;stop-opacity:1" />
    </linearGradient>
    <radialGradient id="glow1" cx="30%" cy="40%" r="40%">
      <stop offset="0%" style="stop-color:#1e3a5f;stop-opacity:0.6" />
      <stop offset="100%" style="stop-color:#0a0a1a;stop-opacity:0" />
    </radialGradient>
    <radialGradient id="glow2" cx="70%" cy="60%" r="35%">
      <stop offset="0%" style="stop-color:#2d1b69;stop-opacity:0.4" />
      <stop offset="100%" style="stop-color:#0a0a1a;stop-opacity:0" />
    </radialGradient>
    <radialGradient id="glow3" cx="50%" cy="80%" r="30%">
      <stop offset="0%" style="stop-color:#1a3a4a;stop-opacity:0.3" />
      <stop offset="100%" style="stop-color:#0a0a1a;stop-opacity:0" />
    </radialGradient>
  </defs>
  <!-- Background -->
  <rect width="3840" height="2160" fill="url(#bg)"/>
  <!-- Ambient glows -->
  <rect width="3840" height="2160" fill="url(#glow1)"/>
  <rect width="3840" height="2160" fill="url(#glow2)"/>
  <rect width="3840" height="2160" fill="url(#glow3)"/>
  <!-- Subtle geometric lines -->
  <line x1="0" y1="800" x2="3840" y2="1200" stroke="#1a2744" stroke-width="0.5" opacity="0.3"/>
  <line x1="0" y1="1000" x2="3840" y2="900" stroke="#1a2744" stroke-width="0.5" opacity="0.2"/>
  <line x1="0" y1="1400" x2="3840" y2="1000" stroke="#2d1b4e" stroke-width="0.5" opacity="0.2"/>
  <!-- Center branding area with glow -->
  <circle cx="1920" cy="1000" r="200" fill="none" stroke="#60a5fa" stroke-width="0.5" opacity="0.15"/>
  <circle cx="1920" cy="1000" r="300" fill="none" stroke="#60a5fa" stroke-width="0.3" opacity="0.08"/>
  <circle cx="1920" cy="1000" r="400" fill="none" stroke="#60a5fa" stroke-width="0.2" opacity="0.04"/>
  <!-- Logo text -->
  <text x="1920" y="990" text-anchor="middle" font-family="sans-serif" font-weight="300" font-size="72" fill="#60a5fa" opacity="0.6">SleekOS</text>
  <text x="1920" y="1040" text-anchor="middle" font-family="sans-serif" font-weight="200" font-size="24" fill="#94a3b8" opacity="0.4">Aurora Edition</text>
  <!-- Decorative dots -->
  <circle cx="500" cy="400" r="2" fill="#60a5fa" opacity="0.2"/>
  <circle cx="800" cy="300" r="1.5" fill="#a78bfa" opacity="0.15"/>
  <circle cx="3200" cy="500" r="2" fill="#60a5fa" opacity="0.2"/>
  <circle cx="3400" cy="1800" r="1.5" fill="#a78bfa" opacity="0.15"/>
  <circle cx="200" cy="1600" r="2" fill="#22d3ee" opacity="0.1"/>
  <circle cx="2800" cy="200" r="1" fill="#60a5fa" opacity="0.15"/>
  <circle cx="1200" cy="1800" r="1.5" fill="#a78bfa" opacity="0.1"/>
  <circle cx="2400" cy="1500" r="2" fill="#22d3ee" opacity="0.12"/>
</svg>
SVGEOF

# ─── Nitrogen wallpaper config ──────────────────────────────────────────────
mkdir -p "${ROOTFS_DIR}/etc/skel/.config/nitrogen"
cat > "${ROOTFS_DIR}/etc/skel/.config/nitrogen/nitrogen.cfg" << 'EOF'
[nitrogen]
view=icon
recurse=true
sort=alpha
icon_caps=false
dirs=/usr/share/sleekos/wallpapers;
EOF

cat > "${ROOTFS_DIR}/etc/skel/.config/nitrogen/bg-saved.cfg" << 'EOF'
[xin_-1]
file=/usr/share/sleekos/wallpapers/default.svg
mode=5
bgcolor=#0a0a1a
EOF

# ─── Set default GTK theme for users ───────────────────────────────────────
log_info "Setting default GTK theme..."
mkdir -p "${ROOTFS_DIR}/etc/skel/.config/gtk-3.0"
cat > "${ROOTFS_DIR}/etc/skel/.config/gtk-3.0/settings.ini" << 'EOF'
[Settings]
gtk-theme-name=SleekOS
gtk-icon-theme-name=Papirus-Dark
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=default
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintslight
gtk-xft-rgba=rgb
gtk-application-prefer-dark-theme=1
gtk-decoration-layout=menu:minimize,maximize,close
EOF

cat > "${ROOTFS_DIR}/etc/skel/.gtkrc-2.0" << 'EOF'
gtk-theme-name="SleekOS"
gtk-icon-theme-name="Papirus-Dark"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="default"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH_HORIZ
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=0
gtk-menu-images=0
gtk-enable-event-sounds=0
gtk-enable-input-feedback-sounds=0
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle="hintslight"
gtk-xft-rgba="rgb"
gtk-application-prefer-dark-theme=1
EOF

log_success "SleekOS theme applied"
