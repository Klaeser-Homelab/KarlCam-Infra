# KarlCam Infrastructure Deployment Guide

## Prerequisites

### 1. Proxmox Setup
- ✅ Proxmox nodes at each site (SF: 10.0.0.35, Truckee: TBD)
- ✅ Ubuntu cloud-init template (VM ID 9000)
- ✅ API token: `terraform@pve!terraform-token`
- ✅ Network bridge: `vmbr0`
- ✅ Storage pool: `local-lvm`

### 2. SSH Keys
```bash
# Generate SSH key if you don't have one
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Copy public key content for Terraform config
cat ~/.ssh/id_rsa.pub
```

### 3. Tools Installation
```bash
# Install Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get update && sudo apt-get install terraform

# Install Ansible
sudo apt-get install ansible

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

## Quick Start

### 1. Configure Environment
```bash
cd terraform/environments/sf
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values:
# - proxmox_api_token_secret = "a6c9cf26-19fb-4407-8bcc-6edee0fc2371"
# - ssh_public_key = "ssh-rsa AAAAB3... your-key-here"
```

### 2. Deploy SF Site
```bash
# From project root
./scripts/bootstrap.sh sf
```

### 3. Deploy Multi-Site (Future)
```bash
# When Truckee site is ready
./scripts/deploy-multi-site.sh
```

## What Gets Deployed

### Infrastructure (Terraform)
- **Control Plane**: 1x VM (4 cores, 8GB RAM, 50GB disk)
- **Workers**: 3x VMs (8 cores, 16GB RAM, 100GB disk each)
- **IPs**: 10.0.0.40-43 (SF), 10.0.0.50-53 (Truckee)
- **VM IDs**: 110-118 (SF), 210-218 (Truckee)

### Software Stack (Ansible)
- **K3s**: Lightweight Kubernetes distribution
- **Cilium**: Advanced networking with Cluster Mesh
- **Prometheus**: Metrics collection and alerting
- **Grafana**: Monitoring dashboards
- **Hubble**: Network observability

### KarlCam Services
- **Distributed ML Inference**: Triton Inference Server
- **State Management**: Redis Cluster
- **Storage**: MinIO distributed object storage
- **Rate Limiting**: Envoy proxy with Redis backend

## Access Points

### Grafana Dashboard
```bash
# Get Grafana LoadBalancer IP
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Default credentials: admin / karlcam-admin
```

### Hubble Network Observability
```bash
# Get Hubble UI LoadBalancer IP
kubectl get svc -n kube-system hubble-ui
```

### Kubernetes Dashboard
```bash
# Use kubeconfig from deployment
export KUBECONFIG=./ansible/kubeconfig-sf-karlcam
kubectl get nodes -o wide
```

## Camera Distribution

### SF Site (Urban Fog Detection)
- **Cameras**: 1-18
- **Processing**: Primary ML inference
- **Capacity**: 18 camera streams @ 30fps
- **Specialization**: Urban fog patterns, traffic interaction

### Truckee Site (Mountain Fog Detection)  
- **Cameras**: 19-30
- **Processing**: Edge inference with backup capability
- **Capacity**: 12 camera streams @ 30fps
- **Specialization**: Mountain fog patterns, elevation effects

## Troubleshooting

### VM Boot Issues
```bash
# Check VM status
qm status <vm-id>

# Access console
qm terminal <vm-id>

# Check cloud-init logs
tail -f /var/log/cloud-init-output.log
```

### Ansible Connectivity
```bash
# Test ping to all hosts
ansible all -i inventories/sf/hosts.yml -m ping

# Check SSH connectivity manually
ssh ubuntu@10.0.0.40
```

### K3s Issues
```bash
# Check K3s service status
sudo systemctl status k3s

# View K3s logs
sudo journalctl -u k3s -f

# Check cluster status
kubectl get nodes
```

### Cilium Networking
```bash
# Check Cilium status
cilium status

# Test connectivity
cilium connectivity test

# View Cilium logs
kubectl logs -n kube-system -l k8s-app=cilium
```

## Cleanup

### Destroy Single Site
```bash
./scripts/destroy.sh sf
```

### Destroy All Infrastructure
```bash
./scripts/destroy.sh all
```