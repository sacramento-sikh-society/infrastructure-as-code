# Resource Group
resource "azurerm_resource_group" "aks" {
  name     = "rg-sss-aks"
  location = "westus3"
}

# Virtual Network for AKS (required for Azure CNI Overlay)
resource "azurerm_virtual_network" "aks" {
  name                = "vnet-sss-aks"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  address_space       = ["10.13.0.0/16"]
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks_nodes" {
  name                 = "subnet-sss-aks"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name
  address_prefixes     = ["10.13.1.0/24"]
}

# Public IP for AKS Ingress (static IP for load balancer)
resource "azurerm_public_ip" "aks_ingress" {
  name                = "pip-sss-aks-ingress"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-sss"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "sacsikhsociety"
  kubernetes_version  = "1.34"
  sku_tier            = "Free"

  # System Node Pool
  default_node_pool {
    name            = "system"
    vm_size         = "Standard_D2ads_v6" # AMD EPYC Genoa, 2 vCPU, 8GB RAM (~$83/month)
    vnet_subnet_id  = azurerm_subnet.aks_nodes.id
    os_disk_size_gb = 110         # Max ephemeral disk size for D2ads_v6 temp storage (no extra cost)
    os_disk_type    = "Ephemeral" # Cost-effective, uses local SSD

    # Autoscaling configuration
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3
    node_count           = 1

    # Additional cost optimizations
    only_critical_addons_enabled = false # System pool only runs system pods

    # Node labels and taints
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "prod"
      "nodepoolos"    = "linux"
    }
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # Network Profile - Azure CNI Overlay
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"

    # CNI Overlay requires pod_cidr
    pod_cidr       = "10.244.0.0/16"
    service_cidr   = "10.0.0.0/16"
    dns_service_ip = "10.0.0.10"

    # Load Balancer
    load_balancer_sku = "standard"

    # Outbound type - loadBalancer allows public egress
    outbound_type = "loadBalancer"
  }

  # Maintenance window (optional - helps manage updates)
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [2, 3, 4]
    }
  }

  # Cost optimization settings
  automatic_upgrade_channel = "patch" # Auto-upgrade to latest patch version

  # OIDC and Workload Identity (modern authentication, no extra cost)
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  lifecycle {
    ignore_changes = [
      # Ignore changes to node count as autoscaler manages this
      default_node_pool[0].node_count
    ]
  }
}

# User Node Pool (Spot instances for cost savings)
resource "azurerm_kubernetes_cluster_node_pool" "user_spot" {
  name                  = "spot"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  vm_size               = "Standard_D2ads_v6" # AMD EPYC Genoa, 2 vCPU, 8GB RAM
  vnet_subnet_id        = azurerm_subnet.aks_nodes.id
  os_disk_size_gb       = 110 # Max ephemeral disk size for D2ads_v6 temp storage (no extra cost)
  os_disk_type          = "Ephemeral"

  # Spot instance configuration
  priority        = "Spot"
  eviction_policy = "Delete"
  spot_max_price  = -1 # -1 means pay up to regular price, guarantees capacity if available

  # Autoscaling
  auto_scaling_enabled = true
  min_count            = 1
  max_count            = 3

  # Node labels
  node_labels = {
    "nodepool-type"                         = "spot"
    "environment"                           = "prod"
    "kubernetes.azure.com/scalesetpriority" = "spot"
  }

  # Taint to ensure only spot-tolerant pods schedule here
  node_taints = [
    "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
  ]

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}

# Role Assignment - Allow AKS to manage network resources
resource "azurerm_role_assignment" "aks_network" {
  scope                = azurerm_virtual_network.aks.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# Outputs
output "aks_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_kubeconfig" {
  description = "Kubeconfig for the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

output "aks_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "ingress_public_ip" {
  description = "Public IP address for ingress"
  value       = azurerm_public_ip.aks_ingress.ip_address
}

output "ingress_public_ip_fqdn" {
  description = "FQDN for the ingress public IP (if configured)"
  value       = azurerm_public_ip.aks_ingress.fqdn
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.aks.name
}

output "aks_node_resource_group" {
  description = "Name of the auto-created resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "get_credentials_command" {
  description = "Command to get AKS credentials"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.aks.name} --name ${azurerm_kubernetes_cluster.aks.name}"
}
