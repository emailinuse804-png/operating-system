#!/bin/bash
###############################################################################
# 09-iso.sh - Generate bootable ISO with GRUB (BIOS + UEFI)
# Compatible with Oracle VirtualBox and other hypervisors
###############################################################################

source "$(dirname "$0")/../build.sh" 2>/dev/null || true

log_info "Generating bootable ISO..."

ISO_NAME="sleekos-${SLEEKOS_VERSION}-${ARCH}"
ISO_PATH="${OUTPUT_DIR}/${ISO_NAME}.iso"
ISO_WORK="${BUILD_DIR}/iso-work"

# ─── Clean previous ISO work ───────────────────────────────────────────────
rm -rf "${ISO_WORK}"
mkdir -p "${ISO_WORK}"/{live,boot/grub,EFI/BOOT}

# ─── Unmount chroot filesystems ─────────────────────────────────────────────
log_info "Unmounting chroot filesystems..."
for mp in proc sys dev/pts dev run; do
    umount -lf "${ROOTFS_DIR}/${mp}" 2>/dev/null || true
done

# ─── Create squashfs filesystem ─────────────────────────────────────────────
log_info "Creating compressed filesystem (squashfs)..."
log_info "This may take several minutes..."

mksquashfs "${ROOTFS_DIR}" "${ISO_WORK}/live/filesystem.squashfs" \
    -comp xz \
    -Xbcj x86 \
    -b 1M \
    -no-duplicates \
    -no-recovery \
    -e boot/grub \
    -e proc \
    -e sys \
    -e dev \
    -e run \
    -e tmp

log_success "Squashfs image created"

# ─── Copy kernel and initramfs ──────────────────────────────────────────────
log_info "Copying kernel and initramfs..."

# Find the latest kernel
VMLINUZ=$(ls -1 "${ROOTFS_DIR}"/boot/vmlinuz-* 2>/dev/null | sort -V | tail -1)
INITRD=$(ls -1 "${ROOTFS_DIR}"/boot/initrd.img-* 2>/dev/null | sort -V | tail -1)

if [[ -z "$VMLINUZ" || -z "$INITRD" ]]; then
    log_error "Kernel or initramfs not found!"
    log_info "Available files in /boot:"
    ls -la "${ROOTFS_DIR}/boot/" 2>/dev/null || echo "  (empty)"
    exit 1
fi

cp "$VMLINUZ" "${ISO_WORK}/live/vmlinuz"
cp "$INITRD" "${ISO_WORK}/live/initrd.img"

log_success "Kernel: $(basename $VMLINUZ)"
log_success "Initrd: $(basename $INITRD)"

# ─── GRUB Configuration ────────────────────────────────────────────────────
log_info "Setting up GRUB bootloader..."

# Copy GRUB config
cp "${GRUB_DIR}/grub.cfg" "${ISO_WORK}/boot/grub/grub.cfg"

# Copy GRUB theme
mkdir -p "${ISO_WORK}/boot/grub/theme"
cp -r "${GRUB_DIR}/theme/"* "${ISO_WORK}/boot/grub/theme/" 2>/dev/null || true

# ─── Create BIOS boot image ────────────────────────────────────────────────
log_info "Creating BIOS boot image..."

# Create core.img for BIOS boot
grub-mkimage \
    -O i386-pc \
    -o "${ISO_WORK}/boot/grub/core.img" \
    -p "/boot/grub" \
    biosdisk iso9660 normal search search_fs_file search_fs_uuid search_label \
    configfile linux linux16 loopback squash4 part_gpt part_msdos \
    fat ext2 ls cat echo test true

# Concatenate boot.img and core.img for El Torito BIOS boot
cat /usr/lib/grub/i386-pc/cdboot.img "${ISO_WORK}/boot/grub/core.img" \
    > "${ISO_WORK}/boot/grub/bios.img"

# Copy GRUB modules for BIOS
mkdir -p "${ISO_WORK}/boot/grub/i386-pc"
cp /usr/lib/grub/i386-pc/*.mod "${ISO_WORK}/boot/grub/i386-pc/" 2>/dev/null || true
cp /usr/lib/grub/i386-pc/*.lst "${ISO_WORK}/boot/grub/i386-pc/" 2>/dev/null || true

# ─── Create UEFI boot image ────────────────────────────────────────────────
log_info "Creating UEFI boot image..."

# Create a FAT32 EFI System Partition image
EFI_IMG="${ISO_WORK}/boot/grub/efi.img"
dd if=/dev/zero of="$EFI_IMG" bs=1M count=8
mkfs.fat -F 12 "$EFI_IMG"

# Mount and populate EFI image
EFI_MOUNT="${BUILD_DIR}/efi-mount"
mkdir -p "$EFI_MOUNT"
mount -o loop "$EFI_IMG" "$EFI_MOUNT"

mkdir -p "$EFI_MOUNT/EFI/BOOT"

# Create GRUB EFI binary
grub-mkimage \
    -O x86_64-efi \
    -o "$EFI_MOUNT/EFI/BOOT/BOOTX64.EFI" \
    -p "/boot/grub" \
    boot linux normal configfile part_gpt part_msdos fat ext2 \
    iso9660 loopback search search_fs_file search_fs_uuid search_label \
    ls cat echo test true squash4 gfxterm gfxmenu font png jpeg \
    all_video efi_gop efi_uga

# Also copy GRUB EFI modules
mkdir -p "${ISO_WORK}/boot/grub/x86_64-efi"
cp /usr/lib/grub/x86_64-efi/*.mod "${ISO_WORK}/boot/grub/x86_64-efi/" 2>/dev/null || true
cp /usr/lib/grub/x86_64-efi/*.lst "${ISO_WORK}/boot/grub/x86_64-efi/" 2>/dev/null || true

# Copy EFI binary to ISO structure too
cp "$EFI_MOUNT/EFI/BOOT/BOOTX64.EFI" "${ISO_WORK}/EFI/BOOT/"

umount "$EFI_MOUNT"
rmdir "$EFI_MOUNT"

# ─── Create filesystem manifest ────────────────────────────────────────────
log_info "Creating filesystem manifest..."
chroot "${ROOTFS_DIR}" dpkg-query -W --showformat='${Package}\t${Version}\n' \
    > "${ISO_WORK}/live/filesystem.manifest" 2>/dev/null || true

# Calculate filesystem size
du -sx --block-size=1 "${ROOTFS_DIR}" | cut -f1 \
    > "${ISO_WORK}/live/filesystem.size" 2>/dev/null || true

# ─── Create ISO info files ─────────────────────────────────────────────────
cat > "${ISO_WORK}/.disk/info" 2>/dev/null << EOF || true
${SLEEKOS_NAME} ${SLEEKOS_VERSION} "${SLEEKOS_CODENAME}" - Live ${ARCH}
EOF
mkdir -p "${ISO_WORK}/.disk"
echo "${SLEEKOS_NAME} ${SLEEKOS_VERSION} \"${SLEEKOS_CODENAME}\" - Live ${ARCH}" > "${ISO_WORK}/.disk/info"
touch "${ISO_WORK}/.disk/live"

# ─── Generate ISO image ────────────────────────────────────────────────────
log_info "Generating ISO image with BIOS and UEFI support..."

xorriso -as mkisofs \
    -iso-level 3 \
    -full-iso9660-filenames \
    -volid "SLEEKOS" \
    -publisher "SleekOS Project" \
    -preparer "SleekOS Build System" \
    -appid "SleekOS Live ${SLEEKOS_VERSION}" \
    -eltorito-boot boot/grub/bios.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        --grub2-boot-info \
        --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
    -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
    -append_partition 2 0xef "${ISO_WORK}/boot/grub/efi.img" \
    -graft-points \
    -output "${ISO_PATH}" \
    "${ISO_WORK}"

# ─── Generate checksums ────────────────────────────────────────────────────
log_info "Generating checksums..."
cd "${OUTPUT_DIR}"
sha256sum "${ISO_NAME}.iso" > "${ISO_NAME}.sha256"
md5sum "${ISO_NAME}.iso" > "${ISO_NAME}.md5"

# ─── Summary ───────────────────────────────────────────────────────────────
ISO_SIZE=$(du -h "${ISO_PATH}" | cut -f1)
log_success "ISO generated successfully!"
echo ""
echo "  File: ${ISO_PATH}"
echo "  Size: ${ISO_SIZE}"
echo "  SHA256: $(cat ${OUTPUT_DIR}/${ISO_NAME}.sha256)"
echo ""
echo "  Boot modes: BIOS (Legacy) + UEFI"
echo "  Compatible with: VirtualBox, VMware, QEMU, Hyper-V"
