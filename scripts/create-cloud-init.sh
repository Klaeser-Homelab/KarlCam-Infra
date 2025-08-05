#!/bin/bash
# Create cloud-init snippet file for K3s optimization
# This must be run on the Proxmox host before Terraform

cat > /var/lib/vz/snippets/k3s-cloud-init.yaml << 'EOF'
#cloud-config
package_upgrade: true
packages:
  - curl
  - wget
  - git
  - htop
  - net-tools
runcmd:
  - echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
  - echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
  - echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
  - sysctl -p
  - modprobe overlay
  - modprobe br_netfilter
  - echo 'overlay' >> /etc/modules-load.d/k8s.conf
  - echo 'br_netfilter' >> /etc/modules-load.d/k8s.conf
EOF

echo "Cloud-init snippet created at: /var/lib/vz/snippets/k3s-cloud-init.yaml"
ls -la /var/lib/vz/snippets/