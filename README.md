# Sentinel Foundry AI Workflows

Azure Logic App ARM templates that embed AI-assisted capabilities directly into Microsoft Sentinel workflows using a private Azure AI Foundry LLM endpoint.

This repository is an early proof of concept for Foundry-driven AI and LLM enhancement in SOC workflows. The goal is simple: show that one deployed model can support many operational tasks because the workflow logic and prompt design live in the API call, not in the model itself. Each playbook sends a different structured request - summarize an incident, generate KQL, research an entity, assess severity, or evaluate PIM activity - while the model remains the same.

That same pattern is not limited to Sentinel playbooks. The same endpoint and prompting approach can be reused from Azure Functions, Sentinel workbooks, VS Code tooling, notebooks, and third-party SOAR platforms. This repo is just the starting point.

This pattern works for teams without Microsoft Security Copilot access and as an added capability for teams that have it. It is practical for budget-constrained environments, government clouds, and any team that wants to integrate AI into existing SOC workflows without building a chatbot or adopting a new platform.

The templates were originally built and tested in Azure Government to validate the pattern for federal teams. With endpoint and connection adjustments at deploy time, they work equally well in Azure commercial.

This repository is part of a series. The first article, [Building a SOC AI API with Azure AI Foundry](https://www.techchat.blog/2026/03/28/building-a-soc-ai-api-with-azure-ai-foundry/), covers setting up the Foundry hub, project, and model deployment that these workflows depend on. A follow-up article covering the Logic App workflows in this repo will be published soon.

## Screenshots

<p align="center"><img src="./images/master%20list.png" width="75%"/></p>

## Playbooks

The individual playbooks live under [playbooks/README.md](./playbooks/README.md). That folder also contains the bulk deployment scripts for commercial and government clouds.

| Playbook | Purpose | Screenshot | Deploy |
| --- | --- | --- | --- |
| [close_low_risk_fp_using_foundry_ai](./playbooks/close_low_risk_fp_using_foundry_ai/README.md) | Compare incident against historical closure patterns and close if it matches a likely false positive | [image](./images/close_low_risk_fp_using_foundry_ai.png) | <a href="./playbooks/close_low_risk_fp_using_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [entity_research_using_foundry_ai](./playbooks/entity_research_using_foundry_ai/README.md) | Retrieve and enrich incident entities; more powerful when combined with external grounding | [image](./images/entity_research_using_foundry_ai.png) | <a href="./playbooks/entity_research_using_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [get_incident_tasks_from_foundry_ai](./playbooks/get_incident_tasks_from_foundry_ai/README.md) | Generate up to ten investigation or response tasks and create them on the incident | [image](./images/get_incident_tasks_from_foundry_ai.png) | <a href="./playbooks/get_incident_tasks_from_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [get_kql_from_foundry_ai](./playbooks/get_kql_from_foundry_ai/README.md) | Accept a natural language question via webhook and return a generated KQL query | [image](./images/get_kql_from_foundry_ai.png) | <a href="./playbooks/get_kql_from_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [get_recovery_steps_from_foundry_ai](./playbooks/get_recovery_steps_from_foundry_ai/README.md) | Accept a question via webhook and return structured recovery or response steps | [image](./images/get_recovery_steps_from_foundry_ai.png) | <a href="./playbooks/get_recovery_steps_from_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [prioritize_incident_using_foundry_ai](./playbooks/prioritize_incident_using_foundry_ai/README.md) | Evaluate severity against historical trends, recommend a change, and update the incident | [image](./images/prioritize_incident_using_foundry_ai.png) | <a href="./playbooks/prioritize_incident_using_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [send_foundry_ai_generated_email_summary](./playbooks/send_foundry_ai_generated_email_summary/README.md) | Produce an HTML incident summary for email or Teams; requires a messaging connector in production | [image](./images/send_incident_to_foundry_ai.png) | <a href="./playbooks/send_foundry_ai_generated_email_summary/README.md#deploy-to-azure">deploy</a> |
| [send_incident_to_foundry_ai](./playbooks/send_incident_to_foundry_ai/README.md) | Send incident title, severity, and alerts to the model and add the summary to incident comments | [image](./images/send_incident_to_foundry_ai.png) | <a href="./playbooks/send_incident_to_foundry_ai/README.md#deploy-to-azure">deploy</a> |
| [use_foundry_ai_to_evaluate_pim](./playbooks/use_foundry_ai_to_evaluate_pim/README.md) | Query Entra ID PIM history daily and generate an HTML summary of unusual patterns | [image](./images/use_foundry_ai_to_evaluate_pim.png) | <a href="./playbooks/use_foundry_ai_to_evaluate_pim/README.md#deploy-to-azure">deploy</a> |

## Workbooks

Two Sentinel workbooks are included in [workbooks/README.md](./workbooks/README.md). The root README references them here, and the full workbook descriptions, setup steps, JSON edit instructions, and playbook mappings are all kept in that single workbook README.

## Prerequisites

- Azure subscription (commercial or government) with permission to deploy `Microsoft.Logic/workflows`
- An Azure AI Foundry project and deployed model (see setup steps below)
- Managed identity permissions for the deployed Logic App (see permission table below)

## Setting Up Azure AI Foundry

These workflows call a private Foundry API endpoint using Managed Identity. The [Building a SOC AI API with Azure AI Foundry](https://www.techchat.blog/2026/03/28/building-a-soc-ai-api-with-azure-ai-foundry/) article covers the original federal-focused setup in full detail. The steps below are a quick reference for both Azure Government and Azure commercial.

<p align="center"><img src="./images/Foundry.png" width="75%"/></p>

If you do not already have a Foundry hub and project, follow these steps.

### 1. Create a Resource Group

Create a dedicated resource group for the Foundry environment. This keeps everything isolated and simplifies cleanup.

### 2. Create an Azure AI Foundry Hub

Search for **Azure AI Foundry** in the Azure portal and create a new hub.

- Select identity-based storage access and disable shared key access
- Leave inbound access as public initially
- The hub automatically provisions a storage account and Key Vault

In Azure Government and Azure commercial, the high-level setup is similar, but the deployed inference endpoint format will differ.

### 3. Create a Project

Launch Foundry and create a new project within the hub. The project is your API boundary - the endpoint your Logic Apps will call.

One project typically covers all use cases because behavior is defined by the system prompt in each API request. Create additional projects only when you need separation for security, data, or deployment lifecycle reasons.

### 4. Deploy a Model

Select a model such as GPT-4o using **Microsoft-hosted** deployment with the **Data zone (Standard)** option to keep data within a geographic boundary. You can swap models later without rebuilding the project.

### 5. Note the API Endpoint

After model deployment, copy the actual inferencing endpoint for the deployed model. Do not use the Foundry portal URL, project overview URL, or a generic studio link. The Logic Apps need the model's HTTPS inference endpoint for the deployed chat model.

Get this URI from the deployed model page, endpoint page, or code sample page for the deployment you intend to call. In practice, look for the endpoint shown for chat completions and copy the full HTTPS URL including the deployment name and `api-version`.

Correct Azure Government example:

```text
https://example-foundry.openai.azure.us/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview
```

Correct Azure commercial example:

```text
https://example-foundry.cognitiveservices.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2025-01-01-preview
```

Notes:

- Azure Government commonly uses the `openai.azure.us` domain pattern.
- Azure commercial commonly uses the `cognitiveservices.azure.com` domain pattern.
- The important part is that the URI ends with `/openai/deployments/<deployment-name>/chat/completions?api-version=...`.
- Use the exact deployment name for the model you want these playbooks to call.
- Do not paste the studio home page, project page, or a bare resource URI.

### 6. Assign Permissions

The Logic App Managed Identity requires the following role assignments before workflows will run successfully:

| Role | Scope |
| --- | --- |
| Microsoft Sentinel Responder | Sentinel workspace |
| Cognitive Services User | Foundry resource |
| Microsoft Sentinel Playbook Operator | Sentinel workspace (optional, for manual testing) |

## Deployment

### Deploy to Azure (portal)

Each playbook folder has **Deploy to Azure** and **Deploy to Azure Government** buttons in its own README. If you want to deploy one workflow at a time, use those individual playbook README deployment options. Click the link in the Deploy column of the table above to go to the playbook README and use the correct button for your cloud.

### Deploy all playbooks at once (PowerShell)

Download the repo and run one of the deploy-all scripts from the [playbooks/README.md](./playbooks/README.md) folder. Both scripts prompt for required values if parameters are not supplied on the command line.

**Prerequisites:**
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- PowerShell 7+
- Sign in: `az login` (or `az cloud set --name AzureUSGovernment && az login` for government)
- Contributor rights on the target resource group

**Azure commercial:**

```powershell
.\playbooks\Deploy-All.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

**Azure Government:**

```powershell
az cloud set --name AzureUSGovernment
az login

.\playbooks\Deploy-All-Gov.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

Each script deploys all nine playbooks sequentially and prints a summary table on completion. Failed deployments are flagged and the script exits with a non-zero code.

### Post-deployment steps

After deployment, finish the setup in this order.

### 1. Verify the Foundry endpoint in the playbook

Make sure the `foundryUri` parameter points to the correct deployed model endpoint. This must be the model inference URL for the deployed chat model, not the Foundry studio URL.

Azure Government example:

```text
https://example-foundry.openai.azure.us/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview
```

Azure commercial example:

```text
https://example-foundry.cognitiveservices.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2025-01-01-preview
```

In each Logic App, the action named `HTTP - Call Foundry` should post to that endpoint.

### 2. Assign Managed Identity roles

Assign the following roles to each Logic App system-assigned managed identity before testing:

| Role | Scope |
| --- | --- |
| Microsoft Sentinel Responder | Sentinel workspace |
| Cognitive Services User | Foundry resource |
| Microsoft Sentinel Playbook Operator | Sentinel workspace for analysts who will run Sentinel playbooks manually |

### 3. Replace placeholder connections with Managed Identity connections

Sentinel-based playbooks deploy placeholder connector resources named `placeholder-delete-*`. Replace them with real Managed Identity connections before expecting the playbooks to run successfully.

1. Open the Logic App in the Azure portal.
2. Go to **Logic app designer**.
3. For Microsoft Sentinel actions, create or rebind a Managed Identity connection for the Sentinel workspace.
4. For Azure Monitor Logs actions, create or rebind a Managed Identity connection for the Log Analytics workspace.
5. For the `HTTP - Call Foundry` action, verify the URI is the correct model endpoint and keep authentication set to Managed Identity.
6. Save the Logic App.
7. Delete the `placeholder-delete-*` connector resources after the workflow is fully wired to the new connections.

### 4. Test Sentinel playbooks

For Sentinel-triggered playbooks, test manually from real incidents or manually created demo incidents. In most cases, even closed incidents still work for functional testing.

To test manually, the analyst triggering the playbook needs `Microsoft Sentinel Playbook Operator` on the workspace. You can also attach the playbooks to automation rules for normal incident-driven execution.

## Notes

- Templates deploy placeholder connection stubs following the Sentinel community playbook pattern. Connectors must be authorized post-deploy.
- Some workflows still need runtime hardening before production use.

## Other Folders

- [playbooks/README.md](./playbooks/README.md) - playbook catalog and bulk deployment scripts
- [workbooks/README.md](./workbooks/README.md) - full workbook setup and deployment instructions
- [functions/README.md](./functions/README.md) - placeholder for future Function-based examples using the same Foundry endpoint pattern
    Write-Host "[SKIP] $($pb.Name) - azuredeploy.json not found" -ForegroundColor Yellow
    $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = 'Skipped' })
    continue
  }

  $timestamp   = Get-Date -Format 'yyyyMMddHHmmss'
  $safeName    = $pb.Name -replace '[^A-Za-z0-9-]', '-'
  $deployName  = "$safeName-$timestamp"
  $logicName   = $pb.Name -replace '_', '-'

  Write-Host "`n[DEPLOY] $($pb.Name)" -ForegroundColor Cyan

  $azArgs = @(
    'deployment', 'group', 'create',
    '--resource-group', $ResourceGroup,
    '--name', $deployName,
    '--template-file', $template,
    '--parameters',
      "logicAppName=$logicName",
      "workspaceName=$WorkspaceName",
      "foundryUri=$FoundryUri"
  )

  if ($WhatIf) { $azArgs += '--what-if' }

  & az @azArgs
  $exitCode = $LASTEXITCODE

  $status = if ($exitCode -eq 0) { 'OK' } else { "Failed (exit $exitCode)" }
  $color  = if ($exitCode -eq 0) { 'Green' } else { 'Red' }
  Write-Host "[$status] $($pb.Name)" -ForegroundColor $color
  $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = $status })
}

Write-Host "`n--- Deployment Summary ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Skipped' })
if ($failed.Count -gt 0) {
  Write-Host "$($failed.Count) deployment(s) failed. Review the output above." -ForegroundColor Red
  exit 1
}

*** Add File: C:\repos\Sentinel Foundry AI Workflows\playbooks\Deploy-All-Gov.ps1
#Requires -Version 7.0
<#
.SYNOPSIS
  Deploys all Sentinel Foundry AI playbooks to an Azure Government resource group.

.DESCRIPTION
  Iterates every playbook folder under the current directory and deploys its
  azuredeploy.json using the Azure CLI targeting the AzureUSGovernment cloud.
  Prompts for required values if not supplied as parameters.

  Prerequisites:
    - Azure CLI installed and signed in to AzureUSGovernment:
      az cloud set --name AzureUSGovernment
      az login
    - PowerShell 7+
    - Contributor (or equivalent) rights on the target resource group

.EXAMPLE
  .\Deploy-All-Gov.ps1 -ResourceGroup MyRG -WorkspaceName my-sentinel-ws -FoundryUri https://my-foundry.openai.azure.us/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview

.EXAMPLE
  .\Deploy-All-Gov.ps1  # prompts for all required values interactively
#>
[CmdletBinding(SupportsShouldProcess)]
param(
  [Parameter(Mandatory = $false)]
  [string]$ResourceGroup,

  [Parameter(Mandatory = $false)]
  [string]$WorkspaceName,

  [Parameter(Mandatory = $false)]
  [string]$FoundryUri,

  [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

$currentCloud = (az cloud show --query name -o tsv 2>$null)
if ($currentCloud -ne 'AzureUSGovernment') {
  Write-Host "WARNING: Azure CLI is currently set to '$currentCloud', not AzureUSGovernment." -ForegroundColor Yellow
  Write-Host "Switch with: az cloud set --name AzureUSGovernment && az login" -ForegroundColor Yellow
  $confirm = Read-Host "Continue anyway? (y/N)"
  if ($confirm -ne 'y') { exit 0 }
}

if (-not $ResourceGroup)  { $ResourceGroup  = Read-Host "Resource group name" }
if (-not $WorkspaceName)  { $WorkspaceName  = Read-Host "Log Analytics workspace name" }
if (-not $FoundryUri)     { $FoundryUri     = Read-Host "Foundry endpoint URI" }

$playbooksRoot = $PSScriptRoot
$playbooks = Get-ChildItem -Path $playbooksRoot -Directory | Sort-Object Name

Write-Host "`nDeploying $($playbooks.Count) playbooks to resource group: $ResourceGroup (Azure Government)" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($pb in $playbooks) {
  $template = Join-Path $pb.FullName 'azuredeploy.json'
  if (-not (Test-Path $template)) {
    Write-Host "[SKIP] $($pb.Name) - azuredeploy.json not found" -ForegroundColor Yellow
    $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = 'Skipped' })
    continue
  }

  $timestamp   = Get-Date -Format 'yyyyMMddHHmmss'
  $safeName    = $pb.Name -replace '[^A-Za-z0-9-]', '-'
  $deployName  = "$safeName-$timestamp"
  $logicName   = $pb.Name -replace '_', '-'

  Write-Host "`n[DEPLOY] $($pb.Name)" -ForegroundColor Cyan

  $azArgs = @(
    'deployment', 'group', 'create',
    '--resource-group', $ResourceGroup,
    '--name', $deployName,
    '--template-file', $template,
    '--parameters',
      "logicAppName=$logicName",
      "workspaceName=$WorkspaceName",
      "foundryUri=$FoundryUri"
  )

  if ($WhatIf) { $azArgs += '--what-if' }

  & az @azArgs
  $exitCode = $LASTEXITCODE

  $status = if ($exitCode -eq 0) { 'OK' } else { "Failed (exit $exitCode)" }
  $color  = if ($exitCode -eq 0) { 'Green' } else { 'Red' }
  Write-Host "[$status] $($pb.Name)" -ForegroundColor $color
  $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = $status })
}

Write-Host "`n--- Deployment Summary ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Skipped' })
if ($failed.Count -gt 0) {
  Write-Host "$($failed.Count) deployment(s) failed. Review the output above." -ForegroundColor Red
  exit 1
}

*** Add File: C:\repos\Sentinel Foundry AI Workflows\functions\README.md
# Functions Placeholder

This folder is reserved for future Azure Function examples that use the same Foundry endpoint and Managed Identity pattern shown in the playbooks and workbooks.

Planned use cases include:

- reusable HTTP wrappers for model calls
- enrichment helpers for Sentinel or other SOC tooling
- notebook and VS Code integration helpers

*** Delete File: C:\repos\Sentinel Foundry AI Workflows\Deploy-All.ps1
*** Delete File: C:\repos\Sentinel Foundry AI Workflows\Deploy-All-Gov.ps1