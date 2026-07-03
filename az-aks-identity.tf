# User-Assigned Managed Identity used by GitHub Actions (OIDC) to configure the
# AKS cluster (deploy Traefik, cert-manager, workloads, etc.). GitHub Actions
# federates into this identity — no client secrets are stored anywhere.
resource "azurerm_user_assigned_identity" "aks_admin" {
  name                = "id-sss-aks-admin"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
}

# Allows the identity to run `az aks get-credentials` (listClusterUserCredential).
# With Azure RBAC enabled on the cluster, in-cluster authorization is then
# governed by the RBAC role assignment below.
resource "azurerm_role_assignment" "aks_admin_cluster_user" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service Cluster User Role"
  principal_id         = azurerm_user_assigned_identity.aks_admin.principal_id
}

# Grants full in-cluster admin (Kubernetes cluster-admin) via Azure RBAC.
# Requires `azure_rbac_enabled = true` on the cluster (see az-aks.tf).
resource "azurerm_role_assignment" "aks_admin_rbac_cluster_admin" {
  scope                = azurerm_kubernetes_cluster.aks.id
  role_definition_name = "Azure Kubernetes Service RBAC Cluster Admin"
  principal_id         = azurerm_user_assigned_identity.aks_admin.principal_id
}

# Federated credential: trust GitHub Actions running on the main branch of
# sacramento-sikh-society/iac-tf-az. Scoped to main only so that pull-request
# runs cannot assume this cluster-admin identity.
resource "azurerm_federated_identity_credential" "gha_iac_tf_az_main" {
  name                = "gha-iac-tf-az-main"
  resource_group_name = azurerm_resource_group.aks.name
  parent_id           = azurerm_user_assigned_identity.aks_admin.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = "https://token.actions.githubusercontent.com"
  subject             = "repo:sacramento-sikh-society/iac-tf-az:ref:refs/heads/main"
}

# Outputs — surfaced for the GitHub Actions workflow (azure/login) that
# authenticates using this identity.
output "aks_admin_identity_client_id" {
  description = "Client ID of the user-assigned identity used by GitHub Actions to configure AKS"
  value       = azurerm_user_assigned_identity.aks_admin.client_id
}

output "aks_admin_identity_principal_id" {
  description = "Principal (object) ID of the user-assigned identity"
  value       = azurerm_user_assigned_identity.aks_admin.principal_id
}
