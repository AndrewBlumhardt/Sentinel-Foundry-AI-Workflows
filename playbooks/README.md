# Sentinel Playbooks

This folder contains the individual Logic App playbooks in this repository along with the bulk deployment script.

## Contents

- One folder per playbook, each with its own `README.md` and `azuredeploy.json`
- `Deploy-All.ps1` for Azure commercial and Azure Government

## Bulk Deployment Script

Run this script from the repo root or from this folder.

If you prefer individual deployment, use the **Deploy to Azure** or **Deploy to Azure Government** button in each playbook folder README.

### Prerequisites

The script uses Azure CLI for authentication. Install it from [aka.ms/installazurecli](https://aka.ms/installazurecli) if not already present, then sign in once before running:

```powershell
az login
```

If you have multiple subscriptions and the wrong one is active, either pass `-Subscription` to the script or set the default first:

```powershell
az account set --subscription "<subscription name or ID>"
```

The script prints the active cloud and subscription before deploying so you can confirm it is targeting the correct environment.

### Azure Commercial

```powershell
.\playbooks\Deploy-All.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

To target a specific subscription in one command:

```powershell
.\playbooks\Deploy-All.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri> `
  -Subscription      "<subscription name or ID>"
```

### Azure Government

Add `-Government` to automatically switch the Azure CLI to AzureUSGovernment before deploying:

```powershell
.\playbooks\Deploy-All.ps1 -Government `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

> **Note:** Sign in to Azure Government before running: `az login --environment AzureUSGovernment`

Each deployment pulls templates directly from GitHub - no local files are required.
