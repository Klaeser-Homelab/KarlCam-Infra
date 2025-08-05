variable "vm_name" {
  description = "Name of the virtual machine"
  type        = string
}

variable "vm_id" {
  description = "ID of the virtual machine"
  type        = number
}

variable "vm_description" {
  description = "Description of the virtual machine"
  type        = string
  default     = ""
}

variable "proxmox_node" {
  description = "Proxmox node to deploy VM on"
  type        = string
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "memory_mb" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 20
}

variable "storage_pool" {
  description = "Storage pool for the VM disk"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge for the VM"
  type        = string
  default     = "vmbr0"
}

variable "template_id" {
  description = "Template ID to clone from"
  type        = string
}

variable "ip_address" {
  description = "Static IP address for the VM"
  type        = string
}

variable "subnet_mask" {
  description = "Subnet mask (CIDR notation)"
  type        = string
  default     = "24"
}

variable "gateway" {
  description = "Gateway IP address"
  type        = string
}

variable "ssh_user" {
  description = "SSH username"
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
}

variable "cloud_init_file_id" {
  description = "Cloud-init file ID"
  type        = string
  default     = null
}

variable "boot_order" {
  description = "Boot order"
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags for the VM"
  type        = list(string)
  default     = []
}