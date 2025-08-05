#!/bin/bash
# Provision K3s cluster VMs from template

set -e

# Configuration
TEMPLATE_ID=9000
STORAGE="local-lvm"
BRIDGE="vmbr0"
GATEWAY="10.0.0.1"

# VM Configuration
declare -A VMS=(
    ["sf-k3s-cp-1"]="110 10.0.0.40 4 8192 50"
    ["sf-k3s-worker-1"]="115 10.0.0.45 4 16384 100"
    ["sf-k3s-worker-2"]="116 10.0.0.46 4 16384 100"
    ["sf-k3s-worker-3"]="117 10.0.0.47 4 16384 100"
)

echo "Provisioning K3s cluster VMs..."

for VM_NAME in "${!VMS[@]}"; do
    IFS=' ' read -r VM_ID IP_ADDR CORES MEMORY DISK_SIZE <<< "${VMS[$VM_NAME]}"
    
    echo "Creating VM: ${VM_NAME} (ID: ${VM_ID})"
    
    # Clone from template
    qm clone ${TEMPLATE_ID} ${VM_ID} --name ${VM_NAME} --full
    
    # Configure VM
    qm set ${VM_ID} --cores ${CORES} --memory ${MEMORY}
    qm set ${VM_ID} --ipconfig0 ip=${IP_ADDR}/24,gw=${GATEWAY}
    qm set ${VM_ID} --nameserver 8.8.8.8
    
    # Resize disk
    qm resize ${VM_ID} scsi0 ${DISK_SIZE}G
    
    # Add tags
    if [[ ${VM_NAME} == *"cp"* ]]; then
        qm set ${VM_ID} --tags "k3s,control-plane,sf,karlcam"
    else
        qm set ${VM_ID} --tags "k3s,worker,sf,karlcam"
    fi
    
    # Start VM
    qm start ${VM_ID}
    
    echo "VM ${VM_NAME} created and started"
    sleep 5
done

echo "All VMs provisioned successfully!"
echo ""
echo "Wait for VMs to boot, then run:"
echo "  cd ../ansible"
echo "  ansible-playbook -i inventories/sf/hosts.yml playbooks/site.yml"