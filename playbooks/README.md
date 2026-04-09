# Sentinel Playbooks

This folder contains the individual Logic App playbooks in this repository along with the bulk deployment scripts.

## Contents

- One folder per playbook, each with its own `README.md` and `azuredeploy.json`
- `Deploy-All.ps1` for Azure commercial
- `Deploy-All-Gov.ps1` for Azure Government

## Bulk Deployment Scripts

Run these scripts from the repo root or from this folder.

### Azure Commercial

```powershell
.\playbooks\Deploy-All.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
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

Each script iterates all playbook folders in this directory and deploys any `azuredeploy.json` file it finds.