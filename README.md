# Sentinel Foundry AI Workflows

ARM templates for Azure Logic App workflows that integrate Microsoft Sentinel, Azure Monitor Logs, and Azure OpenAI or Foundry in Azure Government.

![Foundry](./images/Foundry.png)

## Overview

These workflows were exported from an existing environment and repackaged so each workflow folder can stand on its own with:

- `template.json` for deployment
- A local `README.md` with prerequisites, screenshot, and Deploy to Azure buttons

The old `parameters.json` files are not needed in this repo because each template already contains default parameter values, and ARM deployments support direct parameter overrides at deploy time.

## Screenshots

![Workflow list](./images/master%20list.png)

## Workflows

| Workflow | Purpose | Screenshot | Deploy |
| --- | --- | --- | --- |
| [close_low_risk_fp_using_foundry_ai](./close_low_risk_fp_using_foundry_ai/README.md) | Close likely low-risk or repeat false positive incidents | [image](./images/close_low_risk_fp_using_foundry_ai.png) | [deploy](./close_low_risk_fp_using_foundry_ai/README.md#deploy-to-azure) |
| [entity_research_using_foundry_ai](./entity_research_using_foundry_ai/README.md) | Enrich entities from a Sentinel incident | [image](./images/entity_research_using_foundry_ai.png) | [deploy](./entity_research_using_foundry_ai/README.md#deploy-to-azure) |
| [get_incident_tasks_from_foundry_ai](./get_incident_tasks_from_foundry_ai/README.md) | Generate and create incident tasks | [image](./images/get_incident_tasks_from_foundry_ai.png) | [deploy](./get_incident_tasks_from_foundry_ai/README.md#deploy-to-azure) |
| [get_kql_from_foundry_ai](./get_kql_from_foundry_ai/README.md) | Generate KQL from a natural language prompt | [image](./images/get_kql_from_foundry_ai.png) | [deploy](./get_kql_from_foundry_ai/README.md#deploy-to-azure) |
| [get_recovery_steps_from_foundry_ai](./get_recovery_steps_from_foundry_ai/README.md) | Generate recovery guidance from a question | [image](./images/get_recovery_steps_from_foundry_ai.png) | [deploy](./get_recovery_steps_from_foundry_ai/README.md#deploy-to-azure) |
| [prioritize_incident_using_foundry_ai](./prioritize_incident_using_foundry_ai/README.md) | Recommend and update incident severity | [image](./images/prioritize_incident_using_foundry_ai.png) | [deploy](./prioritize_incident_using_foundry_ai/README.md#deploy-to-azure) |
| [send_foundry_ai_generated_email_summary](./send_foundry_ai_generated_email_summary/README.md) | Produce an HTML incident summary for email or messaging | [image](./images/send_incident_to_foundry_ai.png) | [deploy](./send_foundry_ai_generated_email_summary/README.md#deploy-to-azure) |
| [send_incident_to_foundry_ai](./send_incident_to_foundry_ai/README.md) | Add AI-generated response guidance to an incident | [image](./images/send_incident_to_foundry_ai.png) | [deploy](./send_incident_to_foundry_ai/README.md#deploy-to-azure) |
| [use_foundry_ai_to_evaluate_pim](./use_foundry_ai_to_evaluate_pim/README.md) | Review PIM request history for unusual patterns | [image](./images/use_foundry_ai_to_evaluate_pim.png) | [deploy](./use_foundry_ai_to_evaluate_pim/README.md#deploy-to-azure) |

## Prerequisites

- Azure subscription with permission to deploy `Microsoft.Logic/workflows`
- Azure Government selected if you are using the current exported defaults
- Existing `Microsoft.Web/connections` resources for Sentinel and Azure Monitor Logs where required by the template
- An Azure OpenAI or Foundry endpoint reachable at the URI configured in the template
- Managed identity permissions for the deployed Logic App to call Azure OpenAI or Foundry

## Deployment

Each workflow folder includes Deploy to Azure buttons in the same style used by Microsoft Sentinel playbook READMEs.

If you prefer CLI or PowerShell instead of the portal button, use the helper scripts in the repo root.

PowerShell:

```powershell
.\deploy.ps1 -WorkflowFolder close_low_risk_fp_using_foundry_ai -ResourceGroup <resource-group>
```

Bash:

```bash
./deploy.sh close_low_risk_fp_using_foundry_ai <resource-group>
```

Override template parameters at deployment time when your environment differs from the embedded defaults.

PowerShell example:

```powershell
.\deploy.ps1 \
  -WorkflowFolder close_low_risk_fp_using_foundry_ai \
  -ResourceGroup <resource-group> \
  -Parameters @(
    "workflows_close_low_risk_fp_using_foundry_ai_name=my-workflow-name",
    "connections_azuresentinel_4_externalid=/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/connections/azuresentinel-4",
    "connections_azuremonitorlogs_1_externalid=/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.Web/connections/azuremonitorlogs-1"
  )
```

## Notes

- Deploy button links assume the GitHub repository is `AndrewBlumhardt/Sentinel-Foundry-AI-Workflows` on the `main` branch
- Folder names were normalized for common spelling errors
- Some workflows still need runtime hardening before production use