# Azure Email Communication Service


resource "azurerm_resource_group" "cs" {
  name     = "rg-sss-cs"
  location = "westus3"
}


resource "azurerm_email_communication_service" "ecs" {
  name                = "sss-ecs"
  resource_group_name = azurerm_resource_group.cs.name
  data_location       = "United States"
}

# Communication Service — links email domains for programmatic sending (e.g. via Azure SDK / REST)
resource "azurerm_communication_service" "cs" {
  name                = "sss-cs"
  resource_group_name = azurerm_resource_group.cs.name
  data_location       = "United States"
}

# Outputs
output "email_service_name" {
  description = "Name of the Email Communication Service"
  value       = azurerm_email_communication_service.ecs.name
}

output "communication_service_name" {
  description = "Name of the Communication Service"
  value       = azurerm_communication_service.cs.name
}

output "communication_service_primary_connection_string" {
  description = "Primary connection string for the Communication Service (used by SDKs)"
  value       = azurerm_communication_service.cs.primary_connection_string
  sensitive   = true
}

