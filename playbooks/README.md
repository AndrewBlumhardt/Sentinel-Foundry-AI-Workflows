# Sentinel Playbooks

This folder contains the individual Logic App playbooks in this repository along with the bulk deployment scripts.

## Contents

- One folder per playbook, each with its own `README.md` and `azuredeploy.json`
- `Deploy-All.ps1` for Azure commercial
- `Deploy-All-Gov.ps1` for Azure Government

## Bulk Deployment Scripts

Run these scripts from the repo root or from this folder.

If you prefer individual deployment, use the **Deploy to Azure** or **Deploy to Azure Government** button in each playbook folder README.

### Prerequisites

The scripts use Azure CLI for authentication. Install it from [aka.ms/installazurecli](https://aka.ms/installazurecli) if not already present, then sign in once before running:

```powershell
az login
```

If you have multiple subscriptions and the wrong one is active, either pass `-Subscription` to the script or set the default first:

```powershell
az account set --subscription "<subscription name or ID>"
```

The script prints the active subscription name and ID before deploying so you can confirm it is targeting the correct environment.

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

```powershell
az cloud set --name AzureUSGovernment
az login

.\playbooks\Deploy-All-Gov.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

Each script deploys all 9 playbooks using templates pulled directly from GitHub - no local files are required.