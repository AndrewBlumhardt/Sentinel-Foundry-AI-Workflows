# Sanitization Report
Version: v3.0

Generated: 2026-04-08 20:39:02 -05:00

## Files
- Original template: template.json
- Sanitized template: template.sanitized.json
- Parameters file: template.parameters.json

## Changes Applied
- Renamed workflow parameter 'workflows_Get_KQL_From_Foundry_Using_HTTP_MI_name' to 'logicAppName'
- Set workflow location to [resourceGroup().location]
- Parameterized HTTP_-_Call_Foundry.inputs.uri
- Normalized action runAfter values to arrays
- Connection stubs require post-deploy authorization in the Logic App designer

## Required Inputs Before Deployment
- workspaceName
- foundryUri (default placeholder is intentionally non-functional)

## Notes
- Microsoft.Web/connections stub resources are deployed alongside the workflow (Sentinel MCAS sample pattern).
- After deployment, open the Logic App designer and authorize each connection (Sentinel and Azure Monitor Logs).
- No source-environment Foundry URI is retained in output defaults.
