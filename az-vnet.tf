# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-main-${var.location}-01"
  address_space       = ["10.13.0.0/16"]
  location            = var.location
  resource_group_name = "rg-vnet-main-${var.location}-01"
}

# Subnet
resource "azurerm_subnet" "main" {
  name                 = "snet-main-${var.location}-01"
  resource_group_name  = "rg-vnet-main-${var.location}-01"
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.13.13.0/24"]
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-main-${var.location}-01"
  location            = var.location
  resource_group_name = "rg-vnet-main-${var.location}-01"
}

# Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "main" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

# NSG Rule to allow inbound SSH
resource "azurerm_network_security_rule" "ssh" {
  name                        = "Allow-SSH"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefixes     = var.allowed_ssh_cidrs
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.main.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# NSG Rule to allow inbound HTTP
resource "azurerm_network_security_rule" "http" {
  name                        = "Allow-HTTP"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefixes     = ["*"]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.main.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}

# NSG Rule to allow inbound HTTPS
resource "azurerm_network_security_rule" "https" {
  name                        = "Allow-HTTPS"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefixes     = ["*"]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.main.resource_group_name
  network_security_group_name = azurerm_network_security_group.main.name
}