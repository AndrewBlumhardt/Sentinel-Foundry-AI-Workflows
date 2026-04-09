# Generate Email Summary Using Foundry AI

Produces an HTML incident summary designed for email or Teams notifications. For testing, the workflow writes output to incident comments. Production use requires an email-enabled user or a messaging connector such as Office 365 or Teams.

## Prerequisites

- Existing Azure Sentinel API connection
- Existing Azure Monitor Logs API connection
- Azure OpenAI or Foundry endpoint configured in the template
- Managed identity permissions for the deployed Logic App to call the model endpoint

## Screenshot

<p align="center"><img src="../images/send_incident_to_foundry_ai.png" width="75%"/></p>

## Deploy to Azure

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fsend_foundry_ai_generated_email_summary%2Fazuredeploy.json" target="_blank" rel="noopener noreferrer">
    <img src="https://aka.ms/deploytoazurebutton"/>
</a>
<a href="https://portal.azure.us/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAndrewBlumhardt%2FSentinel-Foundry-AI-Workflows%2Fmain%2Fsend_foundry_ai_generated_email_summary%2Fazuredeploy.json" target="_blank" rel="noopener noreferrer">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazuregov.png"/>
</a>

## Notes

- This workflow is part of an API-first SOC pattern where Logic Apps orchestrate inputs and a shared private Foundry endpoint performs the AI task
- The screenshot currently reuses the incident workflow image due to no separate image file for this workflow

