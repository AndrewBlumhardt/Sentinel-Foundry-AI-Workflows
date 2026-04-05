# Evaluate PIM Activity Using Foundry AI

Runs on a daily schedule, queries Entra ID PIM request history from Azure Monitor Logs, compares recent activity against historical patterns, and generates an HTML summary highlighting unusual or notable activity.

## Prerequisites

- Existing Azure Monitor Logs API connection
- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

<p align="center"><img src="../images/use_foundry_ai_to_evaluate_pim.png" width="75%"/></p>

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fuse_foundry_ai_to_evaluate_pim%2Ftemplate.json" target="_blank" rel="noopener noreferrer">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fuse_foundry_ai_to_evaluate_pim%2Ftemplate.json" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- This workflow runs on a recurrence trigger rather than Sentinel incident creation
