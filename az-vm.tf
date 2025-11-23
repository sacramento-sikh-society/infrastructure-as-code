# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-iaas-${var.location}-01"
  location = var.location
}

# Fetch SSH keys from GitHub users
data "http" "github_ssh_keys" {
  for_each = toset(var.admin_authorized_keys)
  url      = "https://github.com/${trimspace(each.value)}.keys"
}

locals {
  # Combine all SSH keys from all GitHub users
  all_ssh_keys = flatten([
    for username, response in data.http.github_ssh_keys : split("\n", trimspace(response.response_body))
  ])
  # Filter out empty lines
  valid_ssh_keys = [for key in local.all_ssh_keys : key if trimspace(key) != ""]
}

module "vm" {
  source              = "./modules/vm"
  vm_count            = 2
  machine_name        = "AVPDEB"
  vm_size             = "Standard_D2s_v6"
  admin_username      = var.admin_username
  ssh_public_keys     = local.valid_ssh_keys
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.main.id
}