# Infrastructure As Code

### Prerequisites
1. An Azure Subscription.
1. Create a Custom Role for this subscription `ALZ Contributor` with the following privileges scoped to your root management group. Create one if one doesn't exist. You cannot do this at a `Tenant Root Group`
    ```json
    "permissions": [
            {
                "actions": [
                    "Microsoft.Authorization/*/read",
                    "Microsoft.Insights/alertRules/*",
                    "Microsoft.Management/managementGroups/delete",
                    "Microsoft.Management/managementGroups/read",
                    "Microsoft.Management/managementGroups/subscriptions/delete",
                    "Microsoft.Management/managementGroups/subscriptions/write",
                    "Microsoft.Management/managementGroups/write",
                    "Microsoft.Management/managementGroups/subscriptions/read",
                    "Microsoft.Network/*",
                    "Microsoft.ResourceHealth/availabilityStatuses/read",
                    "Microsoft.Resources/deployments/*",
                    "Microsoft.Resources/subscriptions/resourceGroups/*",
                    "Microsoft.Support/*"
                ],
                "notActions": [],
                "dataActions": [],
                "notDataActions": []
            }
        ]
    ```
1. Create a Service Principal `iac-tf-spn`.
    1. Create Federated Credentials to have grant github actions access.
    1. Give this service principal following roles.
        1. `ALZ Contributor`
        1. `Key Vault Administrator`
        1. `Key Vault Contributor`
        1. `Storage Account Key Operator Service Role`
        1. `User Access Administrator`
        1. `Owner`

### GitHub Actions Setup

Configure the following repository variables in GitHub (Settings > Secrets and variables > Actions > Variables):

1. **AZURE_CLIENT_ID** - Service Principal Application (client) ID for OIDC authentication
2. **AZURE_TENANT_ID** - Azure AD Tenant ID
3. **AZURE_SUBSCRIPTION_ID** - Azure Subscription ID
4. **TERRAFORM_BACKEND** - Backend configuration (see `backend.hcl.example`):
   ```hcl
   storage_account_name = "your-storage-account-name"
   container_name       = "tfstate"
   key                  = "terraform.tfstate"
   resource_group_name  = "your-backend-resource-group"
   subscription_id      = "your-azure-subscription-id"
   tenant_id            = "your-azure-tenant-id"
   use_oidc            = true
   ```
5. **TERRAFORM_TFVARS** - Terraform variables (see `terraform.tfvars.example`):
   ```hcl
   subscription_id        = "your-azure-subscription-id"
   tenant_id             = "your-azure-tenant-id"
   location              = "westus"
   admin_username        = "azureuser"
   admin_authorized_keys = "ssh-rsa AAAAB3Nza... your-public-key"
   allowed_ssh_cidrs     = "[\"0.0.0.0/0\"]"
   ```