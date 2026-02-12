# SleekOS - Windows-Like x64 Operating System

A modern, sleek x64 operating system with a Windows-inspired UI, built on Linux with GRUB bootloader support, Ollama AI integration, and full web browser support. Ships as a bootable ISO compatible with Oracle VirtualBox and other hypervisors.

## Features

- **Windows-Like Desktop**: Modern taskbar, start menu, system tray, and window management
- **Sleek UI**: Custom GTK theme with blur effects, rounded corners, and smooth animations
- **Ollama AI Assistant**: Built-in AI assistant powered by Ollama with a native chat interface
- **Web Browser**: Firefox ESR pre-installed with a clean profile
- **GRUB Bootloader**: Custom-themed GRUB2 with SleekOS branding
- **VirtualBox Ready**: ISO boots seamlessly in Oracle VirtualBox (and other hypervisors)
- **x64 Architecture**: Full 64-bit support

## System Requirements

### Build Host Requirements
- Debian 12+ or Ubuntu 22.04+ (x86_64)
- At least 10 GB free disk space
- Root/sudo access
- Internet connection

### Virtual Machine Requirements
- 2+ CPU cores
- 2 GB+ RAM (4 GB recommended)
- 20 GB+ virtual disk
- VirtualBox 6.1+ or compatible hypervisor

## Quick Start

### Build the ISO

```bash
# Install build dependencies
sudo make deps

# Build the ISO (requires root)
sudo make build

# The ISO will be at output/sleekos-1.0-amd64.iso
```

### Run in VirtualBox

1. Create a new VM in VirtualBox:
   - Type: Linux
   - Version: Debian (64-bit)
   - RAM: 4096 MB
   - Disk: 20 GB (VDI, dynamically allocated)
2. Mount `output/sleekos-1.0-amd64.iso` as a CD/DVD
3. Boot the VM
4. SleekOS will start in live mode automatically

### Install to Disk

From the live environment, open Terminal and run:

```bash
sudo sleekos-installer
```

## Project Structure

```
sleekos/
├── build.sh                     # Main build orchestrator
├── Makefile                     # Build system entry point
├── config/
│   ├── packages.list            # System packages
│   ├── hostname                 # OS hostname
│   └── sources.list             # APT repository sources
├── grub/
│   ├── grub.cfg                 # GRUB bootloader config
│   └── theme/
│       └── theme.txt            # GRUB visual theme
├── scripts/
│   ├── 01-bootstrap.sh          # Create minimal Debian system
│   ├── 02-configure.sh          # System configuration
│   ├── 03-desktop.sh            # Desktop environment setup
│   ├── 04-apps.sh               # Application installation
│   ├── 05-ollama.sh             # Ollama AI setup
│   ├── 06-theme.sh              # Apply SleekOS theme
│   ├── 07-users.sh              # User account setup
│   ├── 08-cleanup.sh            # Build cleanup
│   └── 09-iso.sh                # ISO image generation
├── rootfs/
│   ├── etc/
│   │   ├── skel/                # Default user home files
│   │   │   └── .config/         # Desktop environment configs
│   │   └── lightdm/             # Display manager config
│   └── usr/
│       ├── local/bin/            # Custom scripts & launchers
│       ├── share/
│       │   ├── sleekos/          # Branding assets
│       │   ├── themes/SleekOS/   # GTK + Openbox theme
│       │   ├── icons/SleekOS/    # Custom icon theme
│       │   └── applications/     # .desktop launchers
│       └── ...
└── iso/
    └── boot/grub/               # ISO GRUB files
```

## Components

### Desktop Environment
- **Window Manager**: Openbox (highly customizable, low resource usage)
- **Compositor**: Picom (blur, shadows, rounded corners, animations)
- **Taskbar**: Tint2 (Windows-like taskbar with system tray)
- **App Launcher**: Rofi (modern start menu replacement)
- **File Manager**: PCManFM (Windows Explorer-like)
- **Terminal**: Sakura (lightweight, tabbed terminal)

### AI Integration
- **Ollama**: Local LLM runner pre-installed
- **SleekAI Chat**: Custom GTK-based chat interface for Ollama
- **System-wide hotkey**: `Super+A` launches AI assistant

### Theming
- Custom dark/light GTK3 theme inspired by Windows 11
- Openbox window decorations with rounded title bars
- Custom icon set
- Animated wallpapers support
- System sounds

## Customization

### Change Wallpaper
Right-click desktop > Set Wallpaper, or copy images to `/usr/share/sleekos/wallpapers/`

### Change Theme
Settings > Appearance > Theme (Light/Dark)

### Add Ollama Models
```bash
ollama pull llama3.2
ollama pull codellama
```

## Default Credentials

- **User**: `sleek`
- **Password**: `sleekos`
- **Root password**: `sleekos`

## Building from Source

```bash
git clone <repository-url>
cd sleekos
sudo make deps    # Install build dependencies
sudo make build   # Build the ISO
sudo make clean   # Clean build artifacts
```

## License

MIT License - See LICENSE file for details.

## Credits

SleekOS is built on top of Debian GNU/Linux and incorporates many open-source projects including the Linux kernel, GRUB, Openbox, Picom, Tint2, Rofi, Firefox, Ollama, and many more.
