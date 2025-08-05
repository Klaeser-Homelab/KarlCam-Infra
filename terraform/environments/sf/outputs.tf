output "control_plane_ips" {
  description = "IP addresses of control plane nodes"
  value       = module.k3s_control_plane[*].vm_ip
}

output "worker_ips" {
  description = "IP addresses of worker nodes"
  value       = module.k3s_workers[*].vm_ip
}

output "control_plane_nodes" {
  description = "Control plane node details"
  value = {
    for i, node in module.k3s_control_plane : node.vm_name => {
      id   = node.vm_id
      ip   = node.vm_ip
      fqdn = node.vm_fqdn
    }
  }
}

output "worker_nodes" {
  description = "Worker node details"
  value = {
    for i, node in module.k3s_workers : node.vm_name => {
      id   = node.vm_id
      ip   = node.vm_ip
      fqdn = node.vm_fqdn
    }
  }
}

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory"
  value       = local_file.ansible_inventory.filename
}