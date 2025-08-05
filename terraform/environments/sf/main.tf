terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.46.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_api_token_id
  password = var.proxmox_api_token_secret
  insecure = true
}

# Create cloud-init snippet for K3s optimization
resource "proxmox_virtual_environment_file" "k3s_cloud_init" {
  content_type = "snippets"
  datastore_id = "local"
  node_name    = var.proxmox_node
  
  source_raw {
    data = <<-EOF
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
    
    file_name = "k3s-cloud-init.yaml"
  }
}

# K3s Control Plane Nodes
module "k3s_control_plane" {
  source = "../../modules/proxmox-vm"
  count  = var.control_plane_count
  
  vm_name        = "sf-k3s-cp-${count.index + 1}"
  vm_id          = 110 + count.index
  vm_description = "KarlCam K3s Control Plane ${count.index + 1} - SF Site"
  proxmox_node   = var.proxmox_node
  
  cpu_cores    = 4
  memory_mb    = 8192
  disk_size_gb = 50
  
  storage_pool    = var.storage_pool
  network_bridge  = var.network_bridge
  template_id     = var.template_id
  
  ip_address  = "10.0.0.${40 + count.index}"
  subnet_mask = "24"
  gateway     = var.gateway
  
  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key
  
  cloud_init_file_id = proxmox_virtual_environment_file.k3s_cloud_init.id
  boot_order         = 1
  tags              = ["k3s", "control-plane", "sf", "karlcam"]
}

# K3s Worker Nodes
module "k3s_workers" {
  source = "../../modules/proxmox-vm"
  count  = var.worker_count
  
  vm_name        = "sf-k3s-worker-${count.index + 1}"
  vm_id          = 115 + count.index
  vm_description = "KarlCam K3s Worker ${count.index + 1} - SF Site"
  proxmox_node   = var.proxmox_node
  
  cpu_cores    = 8
  memory_mb    = 16384
  disk_size_gb = 100
  
  storage_pool    = var.storage_pool
  network_bridge  = var.network_bridge
  template_id     = var.template_id
  
  ip_address  = "10.0.0.${45 + count.index}"
  subnet_mask = "24"
  gateway     = var.gateway
  
  ssh_user       = var.ssh_user
  ssh_public_key = var.ssh_public_key
  
  cloud_init_file_id = proxmox_virtual_environment_file.k3s_cloud_init.id
  boot_order         = 2
  tags              = ["k3s", "worker", "sf", "karlcam"]
}

# Generate Ansible inventory
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.yml.tpl", {
    control_plane_nodes = module.k3s_control_plane
    worker_nodes        = module.k3s_workers
    cluster_name        = "sf-karlcam"
    cluster_id          = 1
  })
  filename = "../../../ansible/inventories/sf/hosts.yml"
}