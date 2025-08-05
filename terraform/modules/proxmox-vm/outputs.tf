output "vm_id" {
  description = "The ID of the created VM"
  value       = proxmox_virtual_environment_vm.node.vm_id
}

output "vm_ip" {
  description = "The IP address of the VM"
  value       = var.ip_address
}

output "vm_name" {
  description = "The name of the VM"
  value       = proxmox_virtual_environment_vm.node.name
}

output "vm_fqdn" {
  description = "The FQDN of the VM"
  value       = "${proxmox_virtual_environment_vm.node.name}.local"
}