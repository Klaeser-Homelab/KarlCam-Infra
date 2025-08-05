#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-sf}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 Bootstrapping KarlCam infrastructure for $ENVIRONMENT"

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "❌ Terraform not installed"; exit 1; }
command -v ansible >/dev/null 2>&1 || { echo "❌ Ansible not installed"; exit 1; }

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(sf|truckee)$ ]]; then
    echo "❌ Invalid environment. Use 'sf' or 'truckee'"
    exit 1
fi

# Change to Terraform environment directory
cd "$PROJECT_ROOT/terraform/environments/$ENVIRONMENT"

# Check if terraform.tfvars exists
if [ ! -f terraform.tfvars ]; then
    echo "📝 Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    echo "⚠️  Please update terraform.tfvars with your actual credentials:"
    echo "   - proxmox_api_token_secret"
    echo "   - ssh_public_key"
    echo ""
    echo "Example values:"
    echo "proxmox_api_token_secret = \"a6c9cf26-19fb-4407-8bcc-6edee0fc2371\""
    echo "ssh_public_key = \"$(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo 'YOUR_SSH_PUBLIC_KEY_HERE')\""
    exit 1
fi

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init

# Validate Terraform configuration
echo "🔍 Validating Terraform configuration..."
terraform validate

# Format Terraform files
echo "🎨 Formatting Terraform files..."
terraform fmt -recursive

# Plan Terraform changes
echo "📋 Planning infrastructure changes..."
terraform plan -out=tfplan

# Confirm before applying
echo ""
echo "🤔 Review the plan above. Apply infrastructure changes? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply Terraform
echo "🏗️  Applying infrastructure changes..."
terraform apply tfplan

# Wait for VMs to be ready
echo "⏳ Waiting for VMs to boot and become accessible..."
sleep 60

# Get VM IPs for verification
echo "📍 Getting VM information..."
terraform output

# Change to Ansible directory
cd "$PROJECT_ROOT/ansible"

# Check if Ansible inventory was generated
if [ ! -f "inventories/$ENVIRONMENT/hosts.yml" ]; then
    echo "❌ Ansible inventory not found. Terraform may have failed."
    exit 1
fi

# Test Ansible connectivity
echo "🔌 Testing Ansible connectivity..."
ansible all -i "inventories/$ENVIRONMENT/hosts.yml" -m ping --timeout 30 || {
    echo "⚠️  Some hosts not reachable yet. Waiting 30 more seconds..."
    sleep 30
    ansible all -i "inventories/$ENVIRONMENT/hosts.yml" -m ping --timeout 30 || {
        echo "❌ Hosts still not reachable. Please check VM status and SSH connectivity."
        exit 1
    }
}

# Install Ansible collections
echo "📚 Installing Ansible collections..."
ansible-galaxy collection install kubernetes.core community.general

# Run Ansible playbooks
echo "🔧 Running Ansible configuration..."
ansible-playbook -i "inventories/$ENVIRONMENT/hosts.yml" playbooks/site.yml

echo ""
echo "✅ KarlCam infrastructure deployment complete for $ENVIRONMENT!"
echo ""
echo "📊 Access points:"
echo "   Grafana: Get LoadBalancer IP with: kubectl get svc -n monitoring kube-prometheus-stack-grafana"
echo "   Hubble UI: Get LoadBalancer IP with: kubectl get svc -n kube-system hubble-ui"
echo ""
echo "🔑 Default credentials:"
echo "   Grafana: admin / karlcam-admin"
echo ""
echo "📁 Kubeconfig saved to: $PROJECT_ROOT/ansible/kubeconfig-$ENVIRONMENT-karlcam"