#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Environment: sf | truckee | all"
    exit 1
fi

destroy_environment() {
    local env=$1
    echo "🔥 Destroying KarlCam infrastructure for $env"
    
    cd "$PROJECT_ROOT/terraform/environments/$env"
    
    if [ ! -f terraform.tfstate ]; then
        echo "⚠️  No Terraform state found for $env, skipping..."
        return
    fi
    
    # Plan destruction
    echo "📋 Planning destruction..."
    terraform plan -destroy -out=destroy-plan
    
    # Confirm destruction
    echo ""
    echo "🤔 This will PERMANENTLY DESTROY all infrastructure for $env. Continue? (y/N)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "❌ Destruction cancelled for $env"
        return
    fi
    
    # Apply destruction
    echo "💥 Destroying infrastructure..."
    terraform apply destroy-plan
    
    # Clean up generated files
    rm -f "$PROJECT_ROOT/ansible/inventories/$env/hosts.yml"
    rm -f "$PROJECT_ROOT/ansible/kubeconfig-$env-karlcam"
    
    echo "✅ Infrastructure destroyed for $env"
}

if [ "$ENVIRONMENT" = "all" ]; then
    echo "🌍 Destroying ALL KarlCam infrastructure"
    echo "⚠️  This will destroy both SF and Truckee sites!"
    echo ""
    echo "🤔 Are you ABSOLUTELY sure? Type 'destroy-all' to confirm:"
    read -r confirmation
    if [ "$confirmation" != "destroy-all" ]; then
        echo "❌ Destruction cancelled"
        exit 1
    fi
    
    destroy_environment "sf"
    destroy_environment "truckee"
    
    echo "🏁 All KarlCam infrastructure has been destroyed"
else
    if [[ ! "$ENVIRONMENT" =~ ^(sf|truckee)$ ]]; then
        echo "❌ Invalid environment. Use 'sf', 'truckee', or 'all'"
        exit 1
    fi
    
    destroy_environment "$ENVIRONMENT"
fi