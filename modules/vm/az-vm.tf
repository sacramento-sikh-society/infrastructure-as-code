# Public IP
resource "azurerm_public_ip" "main" {
  count               = var.count
  name                = "pip-${var.machine_name}${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "main" {
  count               = var.count
  name                = "nic-${var.machine_name}${count.index + 1}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "default"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.count
  name                = "${var.machine_name}${count.index + 1}"
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_keys
    content {
      username   = var.admin_username
      public_key = admin_ssh_key.value
    }
  }

  os_disk {
    name                 = "osdisk-${var.machine_name}${count.index + 1}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = var.vm_os.publisher
    offer     = var.vm_os.offer
    sku       = var.vm_os.sku
    version   = var.vm_os.version
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init.yaml", {
    mount_point = "/mnt/data"
  }))

  disable_password_authentication = true
}

# Premium Managed Data Disk
resource "azurerm_managed_disk" "data" {
  count                = var.count
  name                 = "datadisk-${var.machine_name}${count.index + 1}-${var.vm_disk_size}gb"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = "Premium_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.vm_disk_size
}

# Attach Data Disk to VM
resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  count              = var.count
  managed_disk_id    = azurerm_managed_disk.data[count.index].id
  virtual_machine_id = azurerm_linux_virtual_machine.main[count.index].id
  lun                = 0
  caching            = "ReadWrite"
}

# Outputs
output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.main[*].ip_address
}

output "vm_ids" {
  description = "IDs of the VMs"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_private_ips" {
  description = "Private IP addresses of the VMs"
  value       = azurerm_network_interface.main[*].private_ip_address
}

output "ssh_commands" {
  description = "SSH commands to connect to the VMs"
  value       = [for ip in azurerm_public_ip.main[*].ip_address : "ssh ${var.admin_username}@${ip}"]
}
