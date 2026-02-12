#!/bin/bash
###############################################################################
# 04-apps.sh - Install and configure applications
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Configuring applications..."

# ─── Firefox Configuration ──────────────────────────────────────────────────
log_info "Configuring Firefox ESR..."
mkdir -p "${ROOTFS_DIR}/usr/lib/firefox-esr/distribution"
cat > "${ROOTFS_DIR}/usr/lib/firefox-esr/distribution/policies.json" << 'EOF'
{
    "policies": {
        "DisableTelemetry": true,
        "DisableFirefoxStudies": true,
        "DisablePocket": true,
        "DisableFirefoxAccounts": false,
        "DisableFormHistory": false,
        "DisplayBookmarksToolbar": true,
        "DontCheckDefaultBrowser": true,
        "NoDefaultBookmarks": false,
        "OfferToSaveLogins": true,
        "Homepage": {
            "URL": "https://search.brave.com",
            "StartPage": "homepage"
        },
        "SearchEngines": {
            "Default": "DuckDuckGo"
        },
        "UserMessaging": {
            "WhatsNew": false,
            "ExtensionRecommendations": false,
            "SkipOnboarding": true
        },
        "Preferences": {
            "browser.tabs.warnOnClose": false,
            "browser.shell.checkDefaultBrowser": false,
            "toolkit.legacyUserProfileCustomizations.stylesheets": true,
            "browser.urlbar.suggest.quicksuggest.nonsponsored": false,
            "browser.urlbar.suggest.quicksuggest.sponsored": false,
            "browser.newtabpage.activity-stream.feeds.topsites": false,
            "browser.newtabpage.activity-stream.showSponsored": false,
            "browser.newtabpage.activity-stream.showSponsoredTopSites": false
        },
        "ManagedBookmarks": [
            {
                "toplevel_name": "SleekOS Bookmarks"
            },
            {
                "url": "https://ollama.ai",
                "name": "Ollama AI"
            },
            {
                "url": "https://github.com",
                "name": "GitHub"
            },
            {
                "url": "https://search.brave.com",
                "name": "Brave Search"
            }
        ]
    }
}
EOF

# ─── PCManFM Configuration ─────────────────────────────────────────────────
log_info "Configuring file manager..."
mkdir -p "${ROOTFS_DIR}/etc/skel/.config/pcmanfm/default"
cat > "${ROOTFS_DIR}/etc/skel/.config/pcmanfm/default/pcmanfm.conf" << 'EOF'
[config]
bm_open_method=0

[volume]
mount_on_startup=1
mount_removable=1
autorun=1

[ui]
always_show_tabs=0
max_tab_chars=32
win_width=900
win_height=600
splitter_pos=180
media_in_new_tab=0
desktop_folder_new_win=0
change_tab_on_drop=1
close_on_unmount=1
focus_previous=0
side_pane_mode=places
view_mode=icon
show_hidden=0
sort=name;ascending;
toolbar=newtab;navigation;home;
show_statusbar=1
pathbar_mode_buttons=0
EOF

# ─── Desktop shortcuts ─────────────────────────────────────────────────────
log_info "Creating desktop launchers..."

# Browser shortcut
cat > "${ROOTFS_DIR}/etc/skel/Desktop/firefox.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Web Browser
Comment=Browse the Internet
Icon=firefox-esr
Exec=firefox-esr
Categories=Network;WebBrowser;
Terminal=false
EOF

# File Manager shortcut
cat > "${ROOTFS_DIR}/etc/skel/Desktop/files.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Files
Comment=Access and organize files
Icon=system-file-manager
Exec=pcmanfm
Categories=System;FileTools;FileManager;
Terminal=false
EOF

# Terminal shortcut
cat > "${ROOTFS_DIR}/etc/skel/Desktop/terminal.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Terminal
Comment=Use the command line
Icon=utilities-terminal
Exec=sakura
Categories=System;TerminalEmulator;
Terminal=false
EOF

# AI Assistant shortcut
cat > "${ROOTFS_DIR}/etc/skel/Desktop/sleek-ai.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=SleekAI Assistant
Comment=AI-powered assistant using Ollama
Icon=applications-science
Exec=/usr/local/bin/sleek-ai
Categories=Utility;
Terminal=false
EOF

# Settings shortcut
cat > "${ROOTFS_DIR}/etc/skel/Desktop/settings.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Settings
Comment=System Settings
Icon=preferences-system
Exec=/usr/local/bin/sleekos-settings
Categories=Settings;
Terminal=false
EOF

# Make desktop files executable
chroot "${ROOTFS_DIR}" bash -c '
    chmod +x /etc/skel/Desktop/*.desktop 2>/dev/null || true
'

# ─── Application menu entries ──────────────────────────────────────────────
log_info "Creating application menu entries..."

cat > "${ROOTFS_DIR}/usr/share/applications/sleek-ai.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=SleekAI Assistant
GenericName=AI Assistant
Comment=Chat with AI using Ollama
Icon=applications-science
Exec=/usr/local/bin/sleek-ai
Categories=Utility;
Keywords=ai;ollama;chat;assistant;
Terminal=false
EOF

cat > "${ROOTFS_DIR}/usr/share/applications/sleekos-settings.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=SleekOS Settings
GenericName=System Settings
Comment=Configure SleekOS
Icon=preferences-system
Exec=/usr/local/bin/sleekos-settings
Categories=Settings;System;
Keywords=settings;preferences;configuration;
Terminal=false
EOF

cat > "${ROOTFS_DIR}/usr/share/applications/sleekos-about.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=About SleekOS
GenericName=About
Comment=About this operating system
Icon=help-about
Exec=/usr/local/bin/sleekos-about
Categories=System;
Keywords=about;system;info;
Terminal=false
EOF

log_success "Applications configured"
