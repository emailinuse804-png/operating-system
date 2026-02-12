# SleekOS x64 (Windows-like UI + Ollama + Browser + GRUB ISO)

This repository builds a **bootable x64 Linux live ISO** with:

- A clean, Windows-like desktop feel (XFCE + dark theme + modern icons)
- Browser support (`firefox-esr`, `chromium`)
- Ollama support (automatic first-boot installer service)
- Virtualization support for **Oracle VM VirtualBox**
- GRUB-based boot support for BIOS + UEFI

> Target output: a single `.iso` image that can boot on real hardware or in Oracle VM VirtualBox.

---

## What this project provides

- `build.sh`  
  End-to-end live-build runner for generating the ISO.

- `clean.sh`  
  Cleans all live-build artifacts.

- `scripts/verify_iso.sh`  
  Verifies that the generated ISO includes GRUB and a live root filesystem.

- `config/package-lists/*.list.chroot`  
  Package sets for desktop, browser tooling, virtualization, and base services.

- `config/includes.chroot/...`  
  Files copied into the image (systemd units, desktop entries, configuration files, helper scripts).

- `config/hooks/normal/090-enable-sleek-services.hook.chroot`  
  Chroot hook to mark helper scripts executable and enable the Ollama bootstrap service.

---

## Host requirements (build machine)

Use Debian/Ubuntu host (or equivalent container/VM) and install:

```bash
sudo apt-get update
sudo apt-get install -y \
  live-build debootstrap xorriso squashfs-tools \
  grub-pc-bin grub-efi-amd64-bin mtools dosfstools
```

---

## Build the ISO

From repo root:

```bash
chmod +x build.sh clean.sh scripts/verify_iso.sh
sudo ./build.sh
```

Build logs are written to `build.log`.

Expected output file is an ISO in the repository root (for example, `live-image-amd64.hybrid.iso`).

By default, `SECURITY_REPO=false` is used for compatibility with older live-build
versions that still generate the deprecated `bookworm/updates` security path.
If your live-build version supports modern security suites, you can enable it:

```bash
sudo SECURITY_REPO=true ./build.sh
```

---

## Verify ISO structure

```bash
./scripts/verify_iso.sh ./live-image-amd64.hybrid.iso
```

The checker confirms:

- `/boot/grub/grub.cfg` exists
- `/live/filesystem.squashfs` exists

---

## Run in Oracle VM VirtualBox

1. Create VM:
   - Type: Linux
   - Version: Debian (64-bit) or Ubuntu (64-bit)
   - RAM: 4096 MB or more
   - CPU: 2+ cores
   - Video: 128 MB, VMSVGA
2. Attach generated ISO as optical drive.
3. Boot VM (GRUB menu should appear).
4. Login to XFCE session.
5. Run `sleek-postinstall-check` from terminal for quick runtime validation.

---

## Ollama behavior

Ollama is installed by the `sleek-ollama-bootstrap.service` service on first boot
when network is available.

- Service script: `/usr/local/sbin/sleek-ollama-bootstrap`
- Marker file after success: `/var/lib/sleek/ollama-bootstrap.done`
- Desktop launcher: **Ollama Chat**

If internet is unavailable on first boot, the service retries on next boot.

---

## Notes

- This is a Linux-based custom ISO, not a Windows binary clone.
- Theme defaults are tuned for a sleek Windows-like desktop experience.
- You can extend package lists and includes to customize apps, models, and branding.
