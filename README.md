# Infrastructure As Code

### Prerequisites
1. An Azure Subscription.
1. Create a Custom Role for this subscription `ALZ Contributor` with the following privileges scoped to your root management group. Create one if one doesn't exist. You cannot do this a `Tenant Root Group`
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