#!/bin/bash
# Health check script for K3s cluster infrastructure

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
declare -A VMS=(
    ["sf-k3s-cp-1"]="110 10.0.0.40"
    ["sf-k3s-worker-1"]="115 10.0.0.45"
    ["sf-k3s-worker-2"]="116 10.0.0.46"
    ["sf-k3s-worker-3"]="117 10.0.0.47"
)

echo "=== K3s Cluster Health Check ==="
echo ""

# Check if running on Proxmox node
if ! command -v qm &> /dev/null; then
    echo -e "${YELLOW}Warning: This script should be run on the Proxmox node${NC}"
    echo ""
fi

# Function to check VM status
check_vm() {
    local vm_name=$1
    local vm_id=$2
    local vm_ip=$3
    
    echo -n "Checking ${vm_name} (ID: ${vm_id}, IP: ${vm_ip})... "
    
    # Check if VM exists
    if ! qm status ${vm_id} &> /dev/null; then
        echo -e "${RED}NOT FOUND${NC}"
        return 1
    fi
    
    # Check VM status
    local status=$(qm status ${vm_id} | grep -oP 'status: \K\w+')
    if [ "$status" != "running" ]; then
        echo -e "${RED}${status^^}${NC}"
        return 1
    fi
    
    # Check network connectivity
    if ping -c 1 -W 2 ${vm_ip} &> /dev/null; then
        echo -e "${GREEN}OK${NC} (running, network OK)"
    else
        echo -e "${YELLOW}RUNNING${NC} (network unreachable)"
        return 1
    fi
    
    return 0
}

# Check VMs
echo "1. Checking VM Status:"
echo "----------------------"
failed=0
for vm_name in "${!VMS[@]}"; do
    IFS=' ' read -r vm_id vm_ip <<< "${VMS[$vm_name]}"
    if ! check_vm "$vm_name" "$vm_id" "$vm_ip"; then
        ((failed++))
    fi
done
echo ""

# Check SSH connectivity
echo "2. Checking SSH Connectivity:"
echo "-----------------------------"
for vm_name in "${!VMS[@]}"; do
    IFS=' ' read -r vm_id vm_ip <<< "${VMS[$vm_name]}"
    echo -n "SSH to ${vm_name} (${vm_ip})... "
    
    if timeout 5 ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 ubuntu@${vm_ip} exit 2>/dev/null; then
        echo -e "${GREEN}OK${NC}"
    else
        echo -e "${RED}FAILED${NC}"
        ((failed++))
    fi
done
echo ""

# Check K3s service (if accessible)
echo "3. Checking K3s Services:"
echo "-------------------------"
control_plane_ip="10.0.0.40"
echo -n "K3s API Server... "
if timeout 5 curl -sk https://${control_plane_ip}:6443 &> /dev/null; then
    echo -e "${GREEN}OK${NC}"
else
    echo -e "${YELLOW}NOT ACCESSIBLE${NC} (may need kubeconfig)"
fi
echo ""

# Summary
echo "=== Summary ==="
if [ $failed -eq 0 ]; then
    echo -e "${GREEN}All checks passed!${NC}"
else
    echo -e "${RED}${failed} checks failed${NC}"
    echo ""
    echo "Troubleshooting tips:"
    echo "- Check if VMs are fully booted: qm list"
    echo "- Check cloud-init status: ssh ubuntu@<IP> cloud-init status"
    echo "- Check SSH keys: ssh-keygen -f ~/.ssh/id_rsa -y"
    echo "- Check network: ip route show"
fi

exit $failed