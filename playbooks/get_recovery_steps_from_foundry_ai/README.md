# Generate Recovery Steps Using Foundry AI

Accepts a question via webhook, typically triggered from a Sentinel workbook, and returns structured recovery or response steps using Managed Identity for authentication. Grounding on internal SOPs or runbooks can be added through the system prompt.

## Prerequisites

- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

<p align="center"><img src="../../images/get_recovery_steps_from_foundry_ai.png" width="75%"/></p>

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fplaybooks%2Fget_recovery_steps_from_foundry_ai%2Fazuredeploy.json" target="_blank" rel="noopener noreferrer">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fplaybooks%2Fget_recovery_steps_from_foundry_ai%2Fazuredeploy.json" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- After deployment, copy the generated HTTP callback URL into the workbook or caller that will invoke the workflow



