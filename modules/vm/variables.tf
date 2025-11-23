variable "count" {
  description = "Number of VMs to create"
  type        = number
  default     = 1
}

variable "location" {
  description = "Azure region for the VM"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "subnet_id" {
  description = "ID of the subnet to deploy VMs into"
  type        = string
}

variable "os_disk_size_gb" {
  description = "Size of the OS disk in GB"
  type        = number
  default     = 64
}

variable "vm_disk_size" {
  description = "Size of the VM's data disk in GB"
  type        = number
  default     = 256
}

variable "vm_size" {
  description = "Size of the VM"
  type        = string
  default     = "Standard_D2s_v6"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "admin"
}

variable "ssh_public_keys" {
  description = "List of SSH public keys for VM access"
  type        = list(string)
  default     = []
}

variable "machine_name" {
  description = "Base name for the VM"
  type        = string
}

variable "vm_os" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
  description = "Operating system details for the VM"
  default = {
    publisher = "debian"
    offer     = "debian-13"
    sku       = "13-gen2"
    version   = "latest"
  }

  validation {
    condition = contains([
      # AlmaLinux
      jsonencode({ publisher = "almalinux", offer = "almalinux-x86_64", sku = "9-gen2", version = "latest" }),
      # Ubuntu
      jsonencode({ publisher = "Canonical", offer = "ubuntu-24_04-lts", sku = "server", version = "latest" }),
      jsonencode({ publisher = "Canonical", offer = "ubuntu-24_04-lts", sku = "minimal", version = "latest" }),
      # Debian
      jsonencode({ publisher = "debian", offer = "debian-13", sku = "13-gen2", version = "latest" })
    ], jsonencode(var.vm_os))
    error_message = "The vm_os must be one of the allowed OS configurations"
  }
}