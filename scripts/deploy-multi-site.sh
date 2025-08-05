#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🌍 KarlCam Multi-Site Deployment"
echo "================================="

# Deploy SF site first (primary)
echo ""
echo "🏙️  Deploying San Francisco site (Primary)..."
"$SCRIPT_DIR/bootstrap.sh" sf

# Wait before deploying Truckee
echo ""
echo "⏳ Waiting 30 seconds before deploying Truckee site..."
sleep 30

# Deploy Truckee site (secondary)
echo ""
echo "🏔️  Deploying Truckee site (Secondary)..."
"$SCRIPT_DIR/bootstrap.sh" truckee

# Configure Cilium Cluster Mesh between sites
echo ""
echo "🔗 Configuring Cilium Cluster Mesh..."
"$SCRIPT_DIR/setup-cluster-mesh.sh"

echo ""
echo "🎉 Multi-site KarlCam deployment complete!"
echo ""
echo "📈 Monitoring stack deployed on both sites"
echo "🔗 Cilium Cluster Mesh configured for cross-site communication"
echo "📹 Ready for camera stream distribution:"
echo "   - SF: Cameras 1-18 (urban fog patterns)"
echo "   - Truckee: Cameras 19-30 (mountain fog patterns)"