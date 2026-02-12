# ═══════════════════════════════════════════════════════════════════════════
# SleekOS Build System
# ═══════════════════════════════════════════════════════════════════════════

SHELL := /bin/bash
.PHONY: all build deps clean iso help check

SLEEKOS_VERSION := 1.0
ISO_NAME := sleekos-$(SLEEKOS_VERSION)-amd64.iso
OUTPUT_DIR := output

# ─── Default target ─────────────────────────────────────────────────────────
all: build

# ─── Help ───────────────────────────────────────────────────────────────────
help:
	@echo ""
	@echo "╔══════════════════════════════════════════════════════════════╗"
	@echo "║              SleekOS Build System                           ║"
	@echo "╚══════════════════════════════════════════════════════════════╝"
	@echo ""
	@echo "  Usage: sudo make [target]"
	@echo ""
	@echo "  Targets:"
	@echo "    help     - Show this help message"
	@echo "    deps     - Install build dependencies"
	@echo "    build    - Build the full ISO (requires root)"
	@echo "    clean    - Remove build artifacts"
	@echo "    check    - Verify build environment"
	@echo ""
	@echo "  Quick Start:"
	@echo "    sudo make deps    # Install dependencies (once)"
	@echo "    sudo make build   # Build the ISO"
	@echo ""
	@echo "  Output: $(OUTPUT_DIR)/$(ISO_NAME)"
	@echo ""

# ─── Install dependencies ──────────────────────────────────────────────────
deps:
	@echo "Installing build dependencies..."
	@bash build.sh deps

# ─── Build ISO ──────────────────────────────────────────────────────────────
build:
	@echo "Building SleekOS v$(SLEEKOS_VERSION)..."
	@bash build.sh build

# ─── Create ISO only (skip bootstrap if rootfs exists) ──────────────────────
iso:
	@echo "Regenerating ISO..."
	@bash scripts/09-iso.sh

# ─── Clean ──────────────────────────────────────────────────────────────────
clean:
	@echo "Cleaning build artifacts..."
	@bash build.sh clean

# ─── Check build environment ───────────────────────────────────────────────
check:
	@echo "Checking build environment..."
	@echo ""
	@echo "Host architecture: $$(uname -m)"
	@echo "Kernel: $$(uname -r)"
	@echo ""
	@echo "Required tools:"
	@for tool in debootstrap xorriso grub-mkimage mksquashfs; do \
		if command -v $$tool &>/dev/null; then \
			echo "  ✅ $$tool: $$(which $$tool)"; \
		else \
			echo "  ❌ $$tool: NOT FOUND"; \
		fi; \
	done
	@echo ""
	@echo "Required packages:"
	@for pkg in debootstrap xorriso grub-pc-bin grub-efi-amd64-bin mtools squashfs-tools; do \
		if dpkg -l $$pkg &>/dev/null 2>&1; then \
			echo "  ✅ $$pkg"; \
		else \
			echo "  ❌ $$pkg"; \
		fi; \
	done
	@echo ""
	@echo "Disk space: $$(df -h . | tail -1 | awk '{print $$4}') available"
