resource "proxmox_virtual_environment_vm" "node" {
  name        = var.vm_name
  node_name   = var.proxmox_node
  vm_id       = var.vm_id
  description = var.vm_description

  cpu {
    cores = var.cpu_cores
    type  = "host"
  }

  memory {
    dedicated = var.memory_mb
  }

  disk {
    datastore_id = var.storage_pool
    file_id      = var.template_id
    interface    = "scsi0"
    size         = var.disk_size_gb
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  serial_device {
    device = "socket"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${var.ip_address}/${var.subnet_mask}"
        gateway = var.gateway
      }
    }
    
    user_account {
      username = var.ssh_user
      keys     = [var.ssh_public_key]
    }
    
    user_data_file_id = var.cloud_init_file_id
  }

  startup {
    order      = var.boot_order
    up_delay   = 30
    down_delay = 30
  }

  tags = var.tags
}