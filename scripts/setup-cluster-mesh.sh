#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🔗 Setting up Cilium Cluster Mesh between SF and Truckee"

# Check if kubeconfig files exist
SF_KUBECONFIG="$PROJECT_ROOT/ansible/kubeconfig-sf-karlcam"
TRUCKEE_KUBECONFIG="$PROJECT_ROOT/ansible/kubeconfig-truckee-karlcam"

if [ ! -f "$SF_KUBECONFIG" ]; then
    echo "❌ SF kubeconfig not found at $SF_KUBECONFIG"
    exit 1
fi

if [ ! -f "$TRUCKEE_KUBECONFIG" ]; then
    echo "❌ Truckee kubeconfig not found at $TRUCKEE_KUBECONFIG"
    exit 1
fi

# Enable Cluster Mesh on SF cluster
echo "🏙️  Enabling Cluster Mesh on SF cluster..."
KUBECONFIG="$SF_KUBECONFIG" cilium clustermesh enable --service-type LoadBalancer

# Enable Cluster Mesh on Truckee cluster  
echo "🏔️  Enabling Cluster Mesh on Truckee cluster..."
KUBECONFIG="$TRUCKEE_KUBECONFIG" cilium clustermesh enable --service-type LoadBalancer

# Wait for Cluster Mesh to be ready
echo "⏳ Waiting for Cluster Mesh to initialize..."
sleep 60

# Check status on both clusters
echo "🔍 Checking Cluster Mesh status on SF..."
KUBECONFIG="$SF_KUBECONFIG" cilium clustermesh status --wait

echo "🔍 Checking Cluster Mesh status on Truckee..."
KUBECONFIG="$TRUCKEE_KUBECONFIG" cilium clustermesh status --wait

# Connect the clusters
echo "🔗 Connecting SF and Truckee clusters..."
KUBECONFIG="$SF_KUBECONFIG" cilium clustermesh connect --destination-context truckee --kubeconfig "$TRUCKEE_KUBECONFIG"

# Verify connectivity
echo "✅ Verifying cross-cluster connectivity..."
KUBECONFIG="$SF_KUBECONFIG" cilium connectivity test --multi-cluster "$TRUCKEE_KUBECONFIG"

echo ""
echo "🎉 Cilium Cluster Mesh setup complete!"
echo ""
echo "📊 Verify mesh status:"
echo "   SF cluster: KUBECONFIG=$SF_KUBECONFIG cilium clustermesh status"
echo "   Truckee cluster: KUBECONFIG=$TRUCKEE_KUBECONFIG cilium clustermesh status"