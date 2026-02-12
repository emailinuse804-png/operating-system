#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "This script needs root privileges (sudo not found)." >&2
    exit 1
  fi
  SUDO="sudo"
else
  SUDO=""
fi

echo "[*] Updating package index..."
$SUDO apt-get update

echo "[*] Installing live ISO build dependencies..."
$SUDO apt-get install -y \
  debootstrap \
  dosfstools \
  grub-efi-amd64-bin \
  grub-pc-bin \
  live-build \
  mtools \
  squashfs-tools \
  xorriso

echo "[+] Dependencies installed."
