#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

DISTRO="${DISTRO:-bookworm}"
ARCH="${ARCH:-amd64}"
ISO_LABEL="${ISO_LABEL:-SLEEK_OS_X64}"
SECURITY_REPO="${SECURITY_REPO:-false}"

if [[ "${EUID}" -ne 0 ]]; then
  echo "build.sh requires root privileges." >&2
  echo "Re-run with: sudo ./build.sh" >&2
  exit 1
fi

required_tools=(
  lb
  debootstrap
  xorriso
  mksquashfs
)

missing=()
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    missing+=("$tool")
  fi
done

if ((${#missing[@]} > 0)); then
  echo "Missing required tools: ${missing[*]}" >&2
  echo "Install on Debian/Ubuntu with:" >&2
  echo "  sudo apt-get update && sudo apt-get install -y live-build debootstrap xorriso squashfs-tools grub-pc-bin grub-efi-amd64-bin mtools dosfstools" >&2
  exit 1
fi

echo "[1/3] Cleaning previous build artifacts"
lb clean --purge

echo "[2/3] Configuring live-build profile"
lb config \
  --mode debian \
  --distribution "$DISTRO" \
  --architectures "$ARCH" \
  --binary-images iso-hybrid \
  --archive-areas "main contrib non-free non-free-firmware" \
  --bootappend-live "boot=live components username=sleek hostname=sleekos quiet splash" \
  --bootloader grub \
  --debian-installer none \
  --firmware-binary true \
  --firmware-chroot true \
  --mirror-bootstrap "http://deb.debian.org/debian/" \
  --mirror-chroot "http://deb.debian.org/debian/" \
  --mirror-binary "http://deb.debian.org/debian/" \
  --mirror-chroot-security "http://security.debian.org/debian-security/" \
  --mirror-binary-security "http://security.debian.org/debian-security/" \
  --security "$SECURITY_REPO" \
  --linux-packages "linux-image-amd64" \
  --iso-application "SleekOS x64" \
  --iso-publisher "SleekOS Project" \
  --iso-volume "$ISO_LABEL"

echo "[3/3] Building ISO (this can take a while)"
lb build 2>&1 | tee build.log

echo "Build completed."
