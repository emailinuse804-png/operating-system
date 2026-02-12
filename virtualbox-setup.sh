#!/bin/bash
###############################################################################
# VirtualBox VM Setup Script
# Creates and configures a VirtualBox VM optimized for SleekOS
# Run this on your HOST machine (not inside the VM)
###############################################################################

set -euo pipefail

VM_NAME="SleekOS"
ISO_PATH="${1:-output/sleekos-1.0-amd64.iso}"
VM_DIR="$HOME/VirtualBox VMs/${VM_NAME}"
DISK_SIZE=20480  # 20 GB
RAM=4096         # 4 GB
VRAM=128         # 128 MB video
CPUS=2

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║           SleekOS VirtualBox Setup                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check VBoxManage
if ! command -v VBoxManage &>/dev/null; then
    echo -e "${RED}Error: VBoxManage not found. Please install VirtualBox first.${NC}"
    echo "Download: https://www.virtualbox.org/wiki/Downloads"
    exit 1
fi

# Check ISO exists
if [[ ! -f "$ISO_PATH" ]]; then
    echo -e "${RED}Error: ISO not found at: ${ISO_PATH}${NC}"
    echo "Usage: $0 [path-to-iso]"
    echo "Default: output/sleekos-1.0-amd64.iso"
    exit 1
fi

ISO_PATH=$(realpath "$ISO_PATH")
echo -e "${CYAN}ISO:${NC}  ${ISO_PATH}"
echo -e "${CYAN}VM:${NC}   ${VM_NAME}"
echo -e "${CYAN}RAM:${NC}  ${RAM} MB"
echo -e "${CYAN}Disk:${NC} ${DISK_SIZE} MB"
echo -e "${CYAN}CPUs:${NC} ${CPUS}"
echo ""

# Delete existing VM if present
if VBoxManage showvminfo "$VM_NAME" &>/dev/null; then
    echo -e "${YELLOW}Removing existing VM '${VM_NAME}'...${NC}"
    VBoxManage unregistervm "$VM_NAME" --delete 2>/dev/null || true
fi

# Create VM
echo -e "${CYAN}Creating VM...${NC}"
VBoxManage createvm --name "$VM_NAME" --ostype "Debian_64" --register

# Configure VM
echo -e "${CYAN}Configuring VM...${NC}"
VBoxManage modifyvm "$VM_NAME" \
    --memory "$RAM" \
    --vram "$VRAM" \
    --cpus "$CPUS" \
    --ioapic on \
    --boot1 dvd \
    --boot2 disk \
    --boot3 none \
    --boot4 none \
    --nic1 nat \
    --natpf1 "ssh,tcp,,2222,,22" \
    --audio-driver pulse \
    --audio-out on \
    --audio-in on \
    --graphicscontroller vmsvga \
    --accelerate3d on \
    --clipboard-mode bidirectional \
    --draganddrop bidirectional \
    --usb on \
    --usbehci on 2>/dev/null || true \
    --firmware efi64 2>/dev/null || VBoxManage modifyvm "$VM_NAME" --firmware bios

# Create and attach virtual disk
echo -e "${CYAN}Creating virtual disk (${DISK_SIZE} MB)...${NC}"
DISK_PATH="${VM_DIR}/${VM_NAME}.vdi"
VBoxManage createmedium disk --filename "$DISK_PATH" --size "$DISK_SIZE" --format VDI

# Add storage controllers
VBoxManage storagectl "$VM_NAME" --name "SATA Controller" --add sata --controller IntelAhci --portcount 2
VBoxManage storagectl "$VM_NAME" --name "IDE Controller" --add ide

# Attach disk and ISO
VBoxManage storageattach "$VM_NAME" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$DISK_PATH"
VBoxManage storageattach "$VM_NAME" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$ISO_PATH"

# Guest additions
echo -e "${CYAN}Configuring guest additions support...${NC}"
VBoxManage modifyvm "$VM_NAME" --nested-hw-virt on 2>/dev/null || true

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  VM '${VM_NAME}' created successfully!                        ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  To start: VBoxManage startvm '${VM_NAME}'                    ║${NC}"
echo -e "${GREEN}║  Or open VirtualBox and click Start                          ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}║  SSH access (after boot):                                    ║${NC}"
echo -e "${GREEN}║    ssh -p 2222 sleek@localhost                               ║${NC}"
echo -e "${GREEN}║    Password: sleekos                                         ║${NC}"
echo -e "${GREEN}║                                                              ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
