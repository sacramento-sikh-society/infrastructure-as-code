# GitHub Actions Terraform CI/CD Workflow

## Quick Setup Checklist

### ✅ Repository Variables (Settings → Secrets and variables → Actions → Variables)
- [ ] `AZURE_SUBSCRIPTION_ID` = `your-subscription-id`
- [ ] `AZURE_TENANT_ID` = `your-tenant-id`
- [ ] `BACKEND_STORAGE_ACCOUNT_NAME` = `yourstgaccount`
- [ ] `BACKEND_CONTAINER_NAME` = `blob-container-name`
- [ ] `BACKEND_KEY` = `az-tf.tfstate`
- [ ] `BACKEND_RESOURCE_GROUP_NAME` = `azure-resource-group-name`
- [ ] `AZURE_CLIENT_ID` = `Your App Registration Client ID`

### 🔐 Repository Secrets
- [ ] None required! OIDC authentication means no secrets needed ✅

### 🛡️ Branch Protection (Settings → Branches → Add rule for `main`)
- [ ] Require a pull request before merging
- [ ] Require approvals (minimum 1)
- [ ] Require status checks: `Security Scan & Format Check` and `Terraform Plan`
- [ ] Require conversation resolution (recommended)
- [ ] Do not allow bypassing settings (recommended)

### 🔑 Azure Federated Credential
Verify in Azure Portal → Azure AD → App registrations → Your App → Certificates & secrets → Federated credentials:
- [ ] **Issuer**: `https://token.actions.githubusercontent.com`
- [ ] **Subject**: `repo:your-org/your-repo:ref:refs/heads/main`
- [ ] **Audience**: `api://AzureADTokenExchange`

### 👤 Azure Permissions
Verify your App Registration has:
- [ ] `Contributor` role on subscription
- [ ] `Storage Blob Data Contributor` on storage account

## Workflow Behavior

### On Pull Request
1. ✅ Security scanning (Checkov, Trivy, TFLint)
2. ✅ Format check (`terraform fmt -check`)
3. ✅ Terraform plan
4. 💬 Posts plan as PR comment
5. 👤 Lead engineer reviews and approves PR

### On Push to Main (After PR Merge)
1. ✅ Security scanning
2. ✅ Format check
3. ♻️ Reuses approved plan from PR
4. ✅ **Terraform apply runs automatically** (no additional approval needed)

## Security Scans

- **Checkov**: Policy-as-code scanner (50+ checks)
- **Trivy**: Misconfiguration scanner
- **TFLint**: Terraform-specific linter with Azure rules