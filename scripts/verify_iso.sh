#!/usr/bin/env bash
set -euo pipefail

if (($# != 1)); then
  echo "Usage: $0 /path/to/sleekos.iso" >&2
  exit 1
fi

ISO_PATH="$1"
if [[ ! -f "$ISO_PATH" ]]; then
  echo "ISO not found: $ISO_PATH" >&2
  exit 1
fi

required_tools=(file xorriso)
for tool in "${required_tools[@]}"; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing tool: $tool" >&2
    exit 1
  fi
done

echo "== ISO identity =="
file "$ISO_PATH"

echo
echo "== Checking GRUB presence =="
if ! xorriso -indev "$ISO_PATH" -find /boot/grub/grub.cfg -exec report_lba >/dev/null 2>&1; then
  echo "ERROR: /boot/grub/grub.cfg not found in ISO." >&2
  exit 1
fi
echo "Found /boot/grub/grub.cfg"

echo
echo "== Checking live root filesystem =="
if ! xorriso -indev "$ISO_PATH" -find /live/filesystem.squashfs -exec report_lba >/dev/null 2>&1; then
  echo "ERROR: /live/filesystem.squashfs not found in ISO." >&2
  exit 1
fi
echo "Found /live/filesystem.squashfs"

echo
echo "ISO verification passed."
