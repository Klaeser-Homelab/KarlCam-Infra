#!/bin/bash
# Create Ubuntu Cloud-Init Template for K3s Nodes

set -e

# Configuration
TEMPLATE_ID=9000
TEMPLATE_NAME="ubuntu-2204-k3s-template"
STORAGE="local-lvm"
UBUNTU_IMG="jammy-server-cloudimg-amd64.img"
UBUNTU_URL="https://cloud-images.ubuntu.com/jammy/current/${UBUNTU_IMG}"

echo "Creating Ubuntu 22.04 template for K3s..."

# Download Ubuntu cloud image
if [ ! -f "${UBUNTU_IMG}" ]; then
    echo "Downloading Ubuntu cloud image..."
    wget ${UBUNTU_URL}
fi

# Create VM
qm create ${TEMPLATE_ID} --name ${TEMPLATE_NAME} --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import disk
qm importdisk ${TEMPLATE_ID} ${UBUNTU_IMG} ${STORAGE}

# Configure VM
qm set ${TEMPLATE_ID} --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${TEMPLATE_ID}-disk-0
qm set ${TEMPLATE_ID} --ide2 ${STORAGE}:cloudinit
qm set ${TEMPLATE_ID} --boot c --bootdisk scsi0
qm set ${TEMPLATE_ID} --serial0 socket --vga serial0
qm set ${TEMPLATE_ID} --agent enabled=1

# Set cloud-init defaults
qm set ${TEMPLATE_ID} --ciuser ubuntu
qm set ${TEMPLATE_ID} --sshkeys ~/.ssh/id_rsa.pub
qm set ${TEMPLATE_ID} --ipconfig0 ip=dhcp

# Resize disk to 20GB
qm resize ${TEMPLATE_ID} scsi0 20G

# Convert to template
qm template ${TEMPLATE_ID}

echo "Template ${TEMPLATE_ID} created successfully!"