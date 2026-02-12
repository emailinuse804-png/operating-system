#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LIVE_BUILD_DIR="${PROJECT_ROOT}/live-build"
DIST_DIR="${PROJECT_ROOT}/dist"
ISO_NAME="winlike-os-amd64.iso"
DRY_RUN=false

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

if [[ ! -d "${LIVE_BUILD_DIR}" ]]; then
  echo "Missing live-build directory: ${LIVE_BUILD_DIR}" >&2
  exit 1
fi

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build (lb) is not installed." >&2
  echo "Run: ./scripts/install-build-deps.sh" >&2
  exit 1
fi

if ! command -v isohybrid >/dev/null 2>&1; then
  echo "isohybrid is not installed." >&2
  echo "Run: ./scripts/install-build-deps.sh (installs syslinux-utils)." >&2
  exit 1
fi

if [[ "${EUID}" -ne 0 ]]; then
  if ! command -v sudo >/dev/null 2>&1; then
    echo "Building an ISO requires root privileges (sudo not found)." >&2
    exit 1
  fi
  SUDO="sudo"
else
  SUDO=""
fi

mkdir -p "${DIST_DIR}"

echo "[*] Cleaning previous live-build artifacts..."
cd "${LIVE_BUILD_DIR}"
$SUDO lb clean --purge

echo "[*] Generating live-build configuration..."
./auto/config

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "[+] Dry-run complete. live-build configuration is valid."
  exit 0
fi

echo "[*] Building ISO (this can take a while)..."
$SUDO lb build

shopt -s nullglob
isos=(live-image-amd64.hybrid.iso live-image-amd64.iso)
SOURCE_ISO=""
for candidate in "${isos[@]}"; do
  if [[ -f "${candidate}" ]]; then
    SOURCE_ISO="${candidate}"
    break
  fi
done

if [[ -z "${SOURCE_ISO}" ]]; then
  echo "Could not find resulting ISO in ${LIVE_BUILD_DIR}" >&2
  exit 1
fi

cp -f "${SOURCE_ISO}" "${DIST_DIR}/${ISO_NAME}"
echo "[+] ISO ready: ${DIST_DIR}/${ISO_NAME}"
