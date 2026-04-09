# Sentinel Foundry AI Workflows

Azure Logic App ARM templates that embed AI-assisted capabilities directly into Microsoft Sentinel workflows using a private Azure AI Foundry LLM endpoint.

This is a working demonstration of a core idea: **one model deployment can serve many different SOC use cases because the logic lives in the API call itself, not in the model.** Each workflow sends a structured request with a system prompt that defines the task - summarize an incident, generate KQL, assess severity, research entities, evaluate PIM activity. The model stays the same. The behavior changes based on how the request is constructed.

This pattern works for teams without Microsoft Security Copilot access and as an added capability for teams that have it. It is practical for budget-constrained environments, government clouds, and any team that wants to integrate AI into existing SOC workflows without building a chatbot or adopting a new platform.

The templates were originally built and tested in Azure Government to validate the pattern for federal teams. With endpoint and connection adjustments at deploy time, they work equally well in Azure commercial.

This repository is part of a series. The first article, [Building a SOC AI API with Azure AI Foundry](https://www.techchat.blog/2026/03/28/building-a-soc-ai-api-with-azure-ai-foundry/), covers setting up the Foundry hub, project, and model deployment that these workflows depend on. A follow-up article covering the Logic App workflows in this repo will be published soon.

## Screenshots

<p align="center"><img src="./images/master%20list.png" width="75%"/></p>

## Playbooks

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

## Prerequisites

- Azure subscription (commercial or government) with permission to deploy `Microsoft.Logic/workflows`
- Existing `Microsoft.Web/connections` resources for Sentinel and Azure Monitor Logs where required by the template
- An Azure AI Foundry project and deployed model (see setup steps below)
- Managed identity permissions for the deployed Logic App (see permission table below)

## Setting Up Azure AI Foundry

These workflows call a private Foundry API endpoint using Managed Identity. The [Building a SOC AI API with Azure AI Foundry](https://www.techchat.blog/2026/03/28/building-a-soc-ai-api-with-azure-ai-foundry/) article covers this setup in full detail. The steps below are a quick reference.

<p align="center"><img src="./images/Foundry.png" width="75%"/></p>

If you do not already have a Foundry hub and project, follow these steps.

### 1. Create a Resource Group

Create a dedicated resource group for the Foundry environment. This keeps everything isolated and simplifies cleanup.

### 2. Create an Azure AI Foundry Hub

Search for **Azure AI Foundry** in the Azure portal and create a new hub.

- Select identity-based storage access and disable shared key access
- Leave inbound access as public initially
- The hub automatically provisions a storage account and Key Vault

### 3. Create a Project

Launch Foundry and create a new project within the hub. The project is your API boundary - the endpoint your Logic Apps will call.

One project typically covers all use cases because behavior is defined by the system prompt in each API request. Create additional projects only when you need separation for security, data, or deployment lifecycle reasons.

### 4. Deploy a Model

Select a model such as GPT-4o using **Microsoft-hosted** deployment with the **Data zone (Standard)** option to keep data within a geographic boundary. You can swap models later without rebuilding the project.

### 5. Note the API Endpoint

After deployment, copy the endpoint URI. The hub creates a Key Vault that can store the API key, but Managed Identity is the preferred authentication method from Azure services and avoids key management entirely.

### 6. Assign Permissions

The Logic App Managed Identity requires the following role assignments before workflows will run successfully:

| Role | Scope |
| --- | --- |
| Microsoft Sentinel Responder | Sentinel workspace |
| Cognitive Services User | Foundry resource |
| Microsoft Sentinel Playbook Operator | Sentinel workspace (optional, for manual testing) |

## Deployment

### Deploy to Azure (portal)

Each playbook folder has **Deploy to Azure** and **Deploy to Azure Government** buttons in its own README. Click the link in the Deploy column of the table above to go to the playbook README and use those buttons.

### Deploy all playbooks at once (PowerShell)

Download the repo and run one of the deploy-all scripts from the repo root. Both scripts prompt for required values if parameters are not supplied on the command line.

**Prerequisites:**
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) installed
- PowerShell 7+
- Sign in: `az login` (or `az cloud set --name AzureUSGovernment && az login` for government)
- Contributor rights on the target resource group

**Azure commercial:**

```powershell
.\Deploy-All.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

**Azure Government:**

```powershell
az cloud set --name AzureUSGovernment
az login

.\Deploy-All-Gov.ps1 `
  -ResourceGroup     <resource-group-name> `
  -WorkspaceName     <log-analytics-workspace-name> `
  -FoundryUri        <foundry-endpoint-uri>
```

Each script deploys all nine playbooks sequentially and prints a summary table on completion. Failed deployments are flagged and the script exits with a non-zero code.

### Post-deployment steps

After deployment, each Logic App will have two placeholder connector resources in the resource group named `placeholder-delete-*`. These must be replaced with authorized connections before the playbooks will run:

1. Open the Logic App in the Azure portal
2. Go to **Logic app designer**
3. Expand any action that shows a connection error and re-authenticate using Managed Identity
4. Save the Logic App
5. Delete the `placeholder-delete-*` connections once all playbooks are wired up

Assign the following roles to each Logic App system-assigned managed identity:

| Role | Scope |
| --- | --- |
| Microsoft Sentinel Responder | Sentinel workspace |
| Cognitive Services User | Foundry resource |

## Notes

- Templates deploy placeholder connection stubs following the Sentinel community playbook pattern. Connectors must be authorized post-deploy.
- Some workflows still need runtime hardening before production use.