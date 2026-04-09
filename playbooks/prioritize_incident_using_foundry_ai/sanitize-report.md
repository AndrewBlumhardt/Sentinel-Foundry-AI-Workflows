# Sanitization Report
Version: v3.0

Generated: 2026-04-08 20:39:02 -05:00

## Files
- Original template: template.json
- Sanitized template: template.sanitized.json
- Parameters file: template.parameters.json

## Changes Applied
- Renamed workflow parameter 'workflows_prioritize_incident_using_foundry_ai_name' to 'logicAppName'
- Removed template parameter connections_azuresentinel_3_externalid
- Removed template parameter connections_azuremonitorlogs_externalid
- Set workflow location to [resourceGroup().location]
- Parameterized HTTP_-_Call_Foundry.inputs.uri
- Parameterized Run_KQL_Query workspace name and left subscription/resource group blank for manual binding
- Normalized action runAfter values to arrays
- Removed connectionProperties from 'azuresentinel-1'
- Normalized connector 'azuresentinel-1' to dynamic connection variable 'MicrosoftSentinelConnectionName'
- Removed connectionProperties from 'azuremonitorlogs'
- Normalized connector 'azuremonitorlogs' to dynamic connection variable 'azuremonitorlogsConnectionName'
- Renamed workflow connection alias 'azuresentinel-1' to 'azuresentinel'
- Added Microsoft.Web/connections stub resource for 'azuresentinel'
- Labeled 'azuresentinel' connection as PLACEHOLDER-DELETE-AFTER-DEPLOY-* in displayName
- Added Microsoft.Web/connections stub resource for 'azuremonitorlogs'
- Labeled 'azuremonitorlogs' connection as PLACEHOLDER-DELETE-AFTER-DEPLOY-* in displayName
- Added workflow dependsOn for 2 connection stub(s)
- Connection stubs require post-deploy authorization in the Logic App designer

## Required Inputs Before Deployment
- workspaceName
- foundryUri (default placeholder is intentionally non-functional)

## Notes
- Microsoft.Web/connections stub resources are deployed alongside the workflow (Sentinel MCAS sample pattern).
- After deployment, open the Logic App designer and authorize each connection (Sentinel and Azure Monitor Logs).
- No source-environment Foundry URI is retained in output defaults.
