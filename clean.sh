#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

if ! command -v lb >/dev/null 2>&1; then
  echo "live-build (lb) is not installed." >&2
  exit 1
fi

lb clean --purge
echo "Live-build artifacts removed."
