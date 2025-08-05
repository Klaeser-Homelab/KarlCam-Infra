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

# Cloud-init optimization will be handled by Ansible instead
# since Proxmox doesn't have a datastore configured for snippets

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
  
  # cloud_init_file_id removed - using basic template cloud-init
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
  
  cpu_cores    = 4
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
  
  # cloud_init_file_id removed - using basic template cloud-init
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