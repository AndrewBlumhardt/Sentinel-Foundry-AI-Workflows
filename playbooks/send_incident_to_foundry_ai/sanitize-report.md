# Sanitization Report
Version: v3.0

Generated: 2026-04-08 21:08:22 -05:00

## Files
- Original template: template.json
- Sanitized template: template.sanitized.json
- Parameters file: template.parameters.json

## Changes Applied
- Renamed workflow parameter 'workflows_send_incident_to_foundry_ai_name' to 'logicAppName'
- Removed template parameter connections_azuresentinel_externalid
- Set workflow location to [resourceGroup().location]
- Parameterized HTTP_-_Call_Foundry.inputs.uri
- Normalized action runAfter values to arrays
- Removed connectionProperties from 'azuresentinel'
- Normalized connector 'azuresentinel' to dynamic connection variable 'MicrosoftSentinelConnectionName'
- Added Microsoft.Web/connections stub resource for 'azuresentinel'
- Labeled 'azuresentinel' connection as PLACEHOLDER-DELETE-AFTER-DEPLOY-* in displayName
- Added workflow dependsOn for 1 connection stub(s)
- Connection stubs require post-deploy authorization in the Logic App designer

## Required Inputs Before Deployment
- workspaceName
- foundryUri (default placeholder is intentionally non-functional)

## Notes
- Microsoft.Web/connections stub resources are deployed alongside the workflow (Sentinel MCAS sample pattern).
- After deployment, open the Logic App designer and authorize each connection (Sentinel and Azure Monitor Logs).
- No source-environment Foundry URI is retained in output defaults.
