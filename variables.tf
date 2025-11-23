variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure Tenant ID"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "westus"
}

variable "admin_username" {
  description = "Admin username for the VM (from GitHub repository variable)"
  type        = string
}

variable "admin_authorized_keys" {
  description = "List of GitHub usernames whose SSH keys should be authorized"
  type        = list(string)
}

variable "allowed_ssh_cidrs" {
  description = "CIDR blocks allowed to access the VM via SSH"
  type        = list(string)
}