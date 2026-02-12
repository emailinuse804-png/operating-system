# WinLike OS x64 (GRUB ISO Builder)

This repository builds a **Windows-like, sleek Ubuntu-based x64 live OS ISO**
with:

- Cinnamon desktop (Windows-style layout)
- GRUB bootloader support (BIOS + UEFI)
- Browser support
- Ollama installer support
- Oracle VM / VirtualBox guest support

The output is a bootable ISO for testing in Oracle VM VirtualBox.

## What is included

- **Desktop/UI**
  - `cinnamon`, `lightdm`, `slick-greeter`
  - Arc + Papirus theming defaults
  - custom wallpaper and dconf defaults
- **Browser support**
  - `epiphany-browser`
  - `qutebrowser`
  - `flatpak` for optional browser installs
- **Ollama support**
  - `/usr/local/bin/install-ollama` helper script
  - menu entries + desktop shortcuts for Ollama setup
- **Oracle VM support**
  - `virtualbox-guest-utils`
  - `virtualbox-guest-x11`
  - `spice-vdagent`
- **Boot/ISO**
  - `amd64` target
  - `iso` image type
  - GRUB configured in live-build options

---

## Repository layout

```text
scripts/
  install-build-deps.sh   # install host-side ISO tooling
  build-iso.sh            # build the bootable ISO

live-build/
  auto/config             # live-build config (amd64 + grub + ubuntu noble)
  config/package-lists/   # package sets
  config/hooks/live/      # chroot hooks
  config/includes.chroot/ # files copied into final live system
```

---

## Build requirements (host machine)

Ubuntu/Debian host with sudo.

Install dependencies:

```bash
./scripts/install-build-deps.sh
```

---

## Build the ISO

```bash
./scripts/build-iso.sh
```

Quick configuration validation (no full ISO build):

```bash
./scripts/build-iso.sh --dry-run
```

Result:

```text
dist/winlike-os-amd64.iso
```

---

## Run in Oracle VM VirtualBox

Recommended VM settings:

- Type: Linux
- Version: Ubuntu (64-bit)
- RAM: 4096 MB+ (8192 MB preferred)
- CPU: 2+ cores
- Video Memory: 128 MB
- Enable 3D Acceleration: Yes
- Storage: attach `dist/winlike-os-amd64.iso` to optical drive

Boot the VM from the ISO and start the live session.

---

## Ollama usage inside the OS

The image ships with an installer helper, not a bundled Ollama binary.

Inside the live system:

```bash
sudo /usr/local/bin/install-ollama
```

Then run:

```bash
ollama run llama3.2
```

You can also open the local endpoint:

```bash
/usr/local/bin/open-ollama-browser
```

---

## Notes

- Building live ISOs can take a while depending on bandwidth and CPU speed.
- Ollama installation requires internet access inside the running OS.
- You can customize package lists under `live-build/config/package-lists/`.
