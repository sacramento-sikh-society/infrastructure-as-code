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