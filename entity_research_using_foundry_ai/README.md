# Entity Research Using Foundry AI

Enriches related Sentinel incident entities such as accounts, file hashes, IPs, hosts, and URLs, then writes the result back to the incident as a comment.

## Prerequisites

- Existing Azure Sentinel API connections for trigger, entity extraction, and comment actions
- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

![entity_research_using_foundry_ai](../images/entity_research_using_foundry_ai.png)

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fentity_research_using_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fentity_research_using_foundry_ai%2Ftemplate.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- This workflow preserves the original exported folder naming
- Update connection resource IDs if your Sentinel connection names differ from the template defaults
