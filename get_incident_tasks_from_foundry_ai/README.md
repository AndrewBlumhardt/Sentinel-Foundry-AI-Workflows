# Generate Incident Tasks Using Foundry AI

Generates up to ten investigation or response tasks based on incident details, then loops through the results to create each task directly on the Sentinel incident and adds supporting context.

## Prerequisites

- Existing Azure Sentinel API connection
- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

![get_incident_tasks_from_foundry_ai](../images/get_incident_tasks_from_foundry_ai.png)

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fget_incident_tasks_from_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fget_incident_tasks_from_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- Override template parameters during deployment if your connection resource IDs or naming differ from the defaults
