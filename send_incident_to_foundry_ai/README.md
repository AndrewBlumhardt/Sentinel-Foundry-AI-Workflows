# Send Incident Context Using Foundry AI

Sends core incident context to the model and writes recommended incident response guidance back to the Sentinel incident as a comment.

## Prerequisites

- Existing Azure Sentinel API connection
- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

![send_incident_to_foundry_ai](../images/send_incident_to_foundry_ai.png)

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fsend_incident_to_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fsend_incident_to_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- Override template parameters during deployment if your Sentinel connection resource ID differs from the default
