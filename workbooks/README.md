# Sentinel Workbooks

These workbooks are lightweight analyst interfaces for the HTTP-triggered playbooks in this repository. Each workbook collects a natural language question, sends it to an associated Logic App webhook, and renders the model response directly in the workbook.

Import the workbook manually, point the lowest custom endpoint block at the correct Logic App trigger URL, and then save it.

## Setup Order

1. Deploy the associated playbook first.
2. In the playbook deployment, make sure `foundryUri` is the real model inference endpoint, not the Foundry portal URL.
3. Assign the Logic App managed identity the required role on the Foundry resource.
4. If the playbook uses Sentinel or Azure Monitor Logs connectors, replace the placeholder connections with Managed Identity connections and save the Logic App.
5. Copy the HTTP POST trigger URL from the Logic App and paste it into the workbook JSON before saving the workbook.

Example Azure Government model endpoint:

```text
https://example-foundry.openai.azure.us/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview
```

Example Azure commercial model endpoint:

```text
https://example-foundry.cognitiveservices.azure.com/openai/deployments/gpt-4.1/chat/completions?api-version=2025-01-01-preview
```

Copy this from the deployed model endpoint or code sample page. Do not use the Foundry studio URL or project overview URL.

## Manual Deployment

1. Open Microsoft Sentinel in the target workspace.
2. Go to **Workbooks**.
3. Select **New**.
4. Open **Advanced Editor**.
5. Paste the contents of the workbook JSON file from the `workbooks` folder in this repo.
6. Find the lowest block that contains `"version":"CustomEndpoint/1.0"`.
7. Replace `"url":""` with the HTTP POST URL from the associated Logic App trigger.
8. Save the workbook.

<p align="center"><img src="../images/Get%20Your%20Webhook%20URL.png" width="75%"/></p>

Example JSON fragment:

```json
{
  "version": "CustomEndpoint/1.0",
  "method": "POST",
  "url": "https://prod-00.westus.logic.azure.com:443/workflows/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa/triggers/manual/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=example-signature",
  "headers": [
    {
      "key": "Content-Type",
      "value": "application/json"
    }
  ]
}
```

To get the webhook URL from the Logic App:

1. Open the deployed Logic App.
2. Open **Logic app designer**.
3. Select the trigger named `HTTP_Request_from_Workbook`.
4. Copy the generated **HTTP POST URL**.
5. Paste that URL into the workbook's lowest custom endpoint block.

## Post-Deployment Checklist

Before using either workbook, confirm the associated Logic App is fully configured:

- `foundryUri` points to the correct deployed model endpoint.
- `HTTP - Call Foundry` uses Managed Identity.
- The Logic App managed identity has `Cognitive Services User` on the Foundry resource.
- Sentinel-based connectors, where present, have been rebound to real Managed Identity connections.
- `placeholder-delete-*` connections have been removed after rebinding.

## Incident Response Assistant

File: `Inciden_ Response_Assistant_Workbook.json`

This workbook sends a natural language security question to the recovery steps playbook and returns a short numbered response plan. The workbook JSON shows a search box, a sample question picker, a submit button, and a final custom endpoint card that renders the answer.

Use it when you want a fast response recommendation for an analyst question without opening a separate tool.

Associated playbook: [playbooks/get_recovery_steps_from_foundry_ai/README.md](../playbooks/get_recovery_steps_from_foundry_ai/README.md)

<p align="center"><img src="../images/Incident%20Response%20Assistant.png" width="75%"/></p>

Notes:

- The workbook includes a built-in sample question list across device, identity, email, network, cloud, web, app, SQL, phone, and AI scenarios.
- The workbook text instructs analysts to refresh after using the dropdown before entering a custom question.
- The webhook target for this workbook should be the trigger URL from the `get_recovery_steps_from_foundry_ai` Logic App.

## KQL Query Assistant

File: `KQL_Query_Assistant_Workbook.json`

This workbook sends a natural language hunting or investigation question to the KQL generation playbook and returns a candidate KQL query. The workbook JSON uses the same pattern as the incident response workbook, but the system prompt behind the associated playbook is tuned to return concise KQL output instead of response steps.

Use it when analysts know what they want to investigate but do not want to hand-write the query.

Associated playbook: [playbooks/get_kql_from_foundry_ai/README.md](../playbooks/get_kql_from_foundry_ai/README.md)

<p align="center"><img src="../images/KQL%20Query%20Assistant.png" width="75%"/></p>

Notes:

- The workbook exposes the same sample question list pattern so you can compare how prompt design changes the returned output.
- The workbook text also instructs analysts to refresh after using the dropdown before entering a custom question.
- The webhook target for this workbook should be the trigger URL from the `get_kql_from_foundry_ai` Logic App.