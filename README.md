# KarlCam Infrastructure as Code

Infrastructure automation for distributed KarlCam fog detection system across SF and Truckee sites.

## Architecture

- **Terraform**: VM provisioning on Proxmox
- **Ansible**: K3s cluster configuration and application deployment
- **Cilium**: Cross-site networking with Cluster Mesh
- **GitOps**: ArgoCD for continuous deployment

## Prerequisites

✅ Proxmox nodes at both sites  
✅ Ubuntu cloud-init template (VM ID 9000)  
✅ Proxmox API token configured  
✅ SSH keys generated  

## Quick Start

```bash
# Deploy SF site
cd terraform/environments/sf
terraform init && terraform apply

# Deploy applications
cd ../../../ansible
ansible-playbook -i inventories/sf/hosts.yml playbooks/site.yml
```

## Directory Structure

```
KarlCam-Infra/
├── terraform/           # Infrastructure provisioning
├── ansible/            # Configuration management
├── k8s-manifests/      # Kubernetes applications
├── scripts/            # Automation scripts
└── docs/              # Documentation
```

## Sites

- **SF**: Control plane + 18 camera streams (urban fog)
- **Truckee**: Edge processing + 12 camera streams (mountain fog)