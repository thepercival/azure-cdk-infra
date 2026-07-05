# Setup Instructions

## GitHub Settings Steps

### 1. Create Environments

Go to **Settings → Environments** and create three environments:

- `dev`
- `acc`
- `prd`

For `prd`, add a **Required reviewer** protection rule to enforce manual approval before production deployments.

---

### 2. Add Secrets to Each Environment

For each environment, go to **Settings → Environments → {env} → Environment secrets** and add:

| Secret | Description |
|---|---|
| `AZURE_CLIENT_ID` | Application (client) ID of the CI/CD App Registration for this environment |
| `AZURE_TENANT_ID` | Your Azure Tenant ID |
| `AZURE_SUBSCRIPTION_ID` | Target Azure Subscription ID |

> `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, and `AZURE_SUBSCRIPTION_ID` can differ per environment if you use separate subscriptions.

---

### 3. Create a CI/CD App Registration in Azure (OIDC / Workload Identity)

Create one App Registration per environment (or share one across dev/acc) for passwordless GitHub Actions authentication.

1. **Azure Portal → Microsoft Entra ID → App registrations → New registration**
2. Name it, e.g. `sp-azure-cdk-infra-dev`
3. After creation go to **Certificates & secrets → Federated credentials → Add credential**
4. Select **GitHub Actions deploying Azure resources**
5. Fill in:
   - Organization: `thepercival`
   - Repository: `azure-cdk-infra`
   - Entity type: **Environment**
   - GitHub environment name: `dev` (repeat for `acc` and `prd`)
6. Copy the **Application (client) ID** → set it as `AZURE_CLIENT_ID` in the matching GitHub environment secret

---

### 4. Grant the CI/CD Principal Permissions in Azure

The CI/CD service principal needs **Contributor** on the resource group (or subscription) to create resources.

```bash
az role assignment create \
  --assignee <AZURE_CLIENT_ID> \
  --role Contributor \
  --scope /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/rg-core-dev
```

> The resource group does not need to exist before running this — the workflow creates it automatically. Assign at subscription scope to cover all three resource groups at once.


