#Requires -Version 7.0

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
$ScriptVersion = "v3.0"

function Write-Ok {
    param([string]$Message)
    Write-Host "[ OK ] $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$Message)
    Write-Host "`n[STEP] $Message" -ForegroundColor Cyan
}

function Ensure-Parameter {
    param(
        [Parameter(Mandatory = $true)] [object]$Template,
        [Parameter(Mandatory = $true)] [string]$Name,
        [Parameter(Mandatory = $true)] [string]$Type,
        [Parameter(Mandatory = $true)] [string]$Description,
        [string]$DefaultValue,
        [switch]$NoDefault,
        [switch]$ForceNoDefault
    )

    if (-not $Template.parameters) {
        $Template | Add-Member -MemberType NoteProperty -Name parameters -Value ([pscustomobject]@{}) -Force
    }

    $existing = $Template.parameters.PSObject.Properties[$Name]
    $paramObj = [ordered]@{
        type = $Type
        metadata = [ordered]@{ description = $Description }
    }

    if (-not $NoDefault -and -not [string]::IsNullOrWhiteSpace($DefaultValue)) {
        $paramObj.defaultValue = $DefaultValue
    }

    if ($existing) {
        $existingObj = $existing.Value
        if (-not $ForceNoDefault -and ($existingObj.PSObject.Properties.Name -contains 'defaultValue') -and -not [string]::IsNullOrWhiteSpace([string]$existingObj.defaultValue)) {
            $paramObj.defaultValue = [string]$existingObj.defaultValue
        }
    }

    $Template.parameters | Add-Member -MemberType NoteProperty -Name $Name -Value ([pscustomobject]$paramObj) -Force
}

function Find-FirstFoundryUri {
    param([string]$RawJson)
    $m = [regex]::Match($RawJson, 'https://[^"\s]*openai\.azure\.us[^"\s]*')
    if ($m.Success) { return $m.Value }
    return ""
}

function Remove-ParameterIfExists {
    param(
        [Parameter(Mandatory = $true)] [object]$Template,
        [Parameter(Mandatory = $true)] [string]$Name
    )

    if ($Template.parameters -and $Template.parameters.PSObject.Properties[$Name]) {
        $Template.parameters.PSObject.Properties.Remove($Name)
    }
}

function Update-ConnectionAliasReferences {
    param(
        [Parameter(Mandatory = $true)] [object]$Node,
        [Parameter(Mandatory = $true)] [string]$OldAlias,
        [Parameter(Mandatory = $true)] [string]$NewAlias
    )

    if ($null -eq $Node) { return $Node }

    if ($Node -is [string]) {
        return $Node.Replace("@parameters('$connections')['$OldAlias']", "@parameters('$connections')['$NewAlias']")
    }

    if ($Node -is [System.Collections.IList]) {
        for ($i = 0; $i -lt $Node.Count; $i++) {
            $Node[$i] = Update-ConnectionAliasReferences -Node $Node[$i] -OldAlias $OldAlias -NewAlias $NewAlias
        }
        return $Node
    }

    if ($Node.PSObject -and $Node.PSObject.Properties) {
        foreach ($p in @($Node.PSObject.Properties)) {
            $Node.($p.Name) = Update-ConnectionAliasReferences -Node $p.Value -OldAlias $OldAlias -NewAlias $NewAlias
        }
    }

    return $Node
}

function Normalize-RunAfterInActions {
    param([Parameter(Mandatory = $true)] [object]$ActionsNode)

    if (-not $ActionsNode -or -not $ActionsNode.PSObject -or -not $ActionsNode.PSObject.Properties) {
        return
    }

    foreach ($actionProp in @($ActionsNode.PSObject.Properties)) {
        $action = $actionProp.Value
        if (-not $action) { continue }

        if ($action.PSObject.Properties['runAfter'] -and $action.runAfter) {
            $normalizedRunAfter = [ordered]@{}
            foreach ($depProp in @($action.runAfter.PSObject.Properties)) {
                $depVal = $depProp.Value
                if ($depVal -is [System.Collections.IList]) {
                    $normalizedRunAfter[$depProp.Name] = @($depVal)
                } else {
                    $normalizedRunAfter[$depProp.Name] = @([string]$depVal)
                }
            }
            $action.runAfter = [pscustomobject]$normalizedRunAfter
        }

        # Recurse into nested actions (e.g., If / Scope branches)
        if ($action.PSObject.Properties['actions'] -and $action.actions) {
            Normalize-RunAfterInActions -ActionsNode $action.actions
        }
        if ($action.PSObject.Properties['else'] -and $action.else -and $action.else.PSObject.Properties['actions'] -and $action.else.actions) {
            Normalize-RunAfterInActions -ActionsNode $action.else.actions
        }
    }
}

Write-Step "Loading template"
$templatePath = "template.json"
$templateRaw = Get-Content -Path $templatePath -Raw
$template = $templateRaw | ConvertFrom-Json -Depth 100
Write-Ok "Template loaded"
Write-Info ("Sanitizer version: " + $ScriptVersion)

if (-not $template.resources) {
    throw "Template has no resources property"
}

if ($template.resources -isnot [System.Collections.IList]) {
    throw "Template resources must be an array"
}

# Guard against accidental single-object serialization.
$template.resources = @($template.resources)

if (-not $template.variables) {
    $template | Add-Member -MemberType NoteProperty -Name variables -Value ([pscustomobject]@{}) -Force
}

$findings = [System.Collections.Generic.List[string]]::new()
$foundryUriDetected = Find-FirstFoundryUri -RawJson $templateRaw
$foundryUriDefault = "SET-LATER-FOUNDRY-URI"
$workspaceNameDefault = "SET-LATER-WORKSPACE-NAME"

Write-Info ("Detected Foundry URI in source: " + ($(if ($foundryUriDetected) { $foundryUriDetected } else { "(not found)" })))

Write-Step "Adding required template parameters"
Ensure-Parameter -Template $template -Name "workspaceName" -Type "string" -Description "Log Analytics workspace name" -DefaultValue $workspaceNameDefault
Ensure-Parameter -Template $template -Name "foundryUri" -Type "string" -Description "Foundry endpoint URI (set after deployment if needed)" -DefaultValue $foundryUriDefault

# Normalize auto-generated workflow parameter name to a cleaner Logic App name parameter.
$workflowNameParam = @($template.parameters.PSObject.Properties | Where-Object { $_.Name -match '^workflows_.*_name$' } | Select-Object -First 1)
if ($workflowNameParam.Count -gt 0) {
    $workflowParamName = $workflowNameParam[0].Name
    $workflowDefault = $null
    if ($workflowNameParam[0].Value.PSObject.Properties.Name -contains 'defaultValue') {
        $workflowDefault = [string]$workflowNameParam[0].Value.defaultValue
    }

    Ensure-Parameter -Template $template -Name "logicAppName" -Type "string" -Description "Logic App Name" -DefaultValue $workflowDefault
    Remove-ParameterIfExists -Template $template -Name $workflowParamName
    $findings.Add("- Renamed workflow parameter '$workflowParamName' to 'logicAppName'") | Out-Null

    foreach ($resource in $template.resources) {
        if ($resource.type -eq 'Microsoft.Logic/workflows') {
            $resource.name = "[parameters('logicAppName')]"
        }
    }
}

# Drop non-required connection external id parameters from template parameters list.
$connectionParams = @($template.parameters.PSObject.Properties | Where-Object { $_.Name -match '^connections_.*_externalid$' })
foreach ($p in $connectionParams) {
    Remove-ParameterIfExists -Template $template -Name $p.Name
    $findings.Add("- Removed template parameter $($p.Name)") | Out-Null
}

# Drop connector internal managed identity parameters to keep deployment UX minimal.
$connectionInternalParams = @($template.parameters.PSObject.Properties | Where-Object { $_.Name -match '^connections_.*' })
foreach ($p in $connectionInternalParams) {
    Remove-ParameterIfExists -Template $template -Name $p.Name
    $findings.Add("- Removed connector internal parameter $($p.Name)") | Out-Null
}

# Remove non-required custom parameters if they exist from prior runs.
Remove-ParameterIfExists -Template $template -Name "subscriptionId"
Remove-ParameterIfExists -Template $template -Name "logAnalyticsResourceGroup"
Remove-ParameterIfExists -Template $template -Name "logAnalyticsWorkspaceName"
Remove-ParameterIfExists -Template $template -Name "workspaceResourceId"
Remove-ParameterIfExists -Template $template -Name "location"
Remove-ParameterIfExists -Template $template -Name "sentinelConnectionName"
Remove-ParameterIfExists -Template $template -Name "azureMonitorLogsConnectionName"

Write-Step "Applying targeted sanitization"

# Remove any Microsoft.Web/connections resources from the source template - they will be regenerated below.
$template.resources = @($template.resources | Where-Object { $_.type -ne 'Microsoft.Web/connections' })

foreach ($resource in $template.resources) {
    if ($resource.type -ne 'Microsoft.Logic/workflows') { continue }

    # Always expose a clean Logic App name prompt in deployment UX.
    $resource.name = "[parameters('logicAppName')]"
    $resource.location = "[resourceGroup().location]"
    $findings.Add("- Set workflow location to [resourceGroup().location]") | Out-Null

    if ($resource.properties -and $resource.properties.definition -and $resource.properties.definition.actions) {
        $actions = $resource.properties.definition.actions

        if ($actions.'HTTP_-_Call_Foundry' -and $actions.'HTTP_-_Call_Foundry'.inputs) {
            $actions.'HTTP_-_Call_Foundry'.inputs.uri = "[parameters('foundryUri')]"
            $findings.Add("- Parameterized HTTP_-_Call_Foundry.inputs.uri") | Out-Null
        }

        if ($actions.'Run_KQL_Query' -and $actions.'Run_KQL_Query'.inputs -and $actions.'Run_KQL_Query'.inputs.queries) {
            # Leave subscription/resource group blank so analysts can bind/select in designer after connector auth.
            $actions.'Run_KQL_Query'.inputs.queries.subscriptions = ""
            $actions.'Run_KQL_Query'.inputs.queries.resourcegroups = ""
            $actions.'Run_KQL_Query'.inputs.queries.resourcename = "[parameters('workspaceName')]"
            $findings.Add("- Parameterized Run_KQL_Query workspace name and left subscription/resource group blank for manual binding") | Out-Null
        }

        # Logic Apps expects FlowStatus[] for runAfter values.
        Normalize-RunAfterInActions -ActionsNode $actions
        $findings.Add("- Normalized action runAfter values to arrays") | Out-Null
    }

    if ($resource.properties -and $resource.properties.parameters -and $resource.properties.parameters.'$connections' -and $resource.properties.parameters.'$connections'.value) {
        $aliasUpdates = @()
        $connectionsToAdd = [System.Collections.Generic.List[object]]::new()

        foreach ($connProp in @($resource.properties.parameters.'$connections'.value.PSObject.Properties)) {
            $conn = $connProp.Value

            $apiName = $null
            if ($conn.id -and $conn.id -match '/managedApis/([a-zA-Z0-9-]+)') {
                $apiName = $Matches[1]
            } elseif ($connProp.Name -match 'azuresentinel') {
                $apiName = 'azuresentinel'
            } elseif ($connProp.Name -match 'azuremonitorlogs') {
                $apiName = 'azuremonitorlogs'
            } else {
                $apiName = ($connProp.Name -replace '[^a-zA-Z0-9]', '').ToLower()
            }

            $connectionVarName = if ($apiName -eq 'azuresentinel') {
                'MicrosoftSentinelConnectionName'
            } else {
                "$($apiName -replace '[^a-zA-Z0-9]', '')ConnectionName"
            }

            $desiredAlias = if ($apiName -eq 'azuresentinel') {
                'azuresentinel'
            } elseif ($apiName -eq 'azuremonitorlogs') {
                'azuremonitorlogs'
            } else {
                $connProp.Name
            }

            if ($connProp.Name -ne $desiredAlias) {
                $aliasUpdates += [pscustomobject]@{ old = $connProp.Name; new = $desiredAlias }
            }

            $connectionNameExpr = if ($apiName -eq 'azuresentinel') {
                "[concat('placeholder-delete-MicrosoftSentinel-', parameters('logicAppName'))]"
            } else {
                "[concat('placeholder-delete-$apiName-', parameters('logicAppName'))]"
            }

            $template.variables | Add-Member -MemberType NoteProperty -Name $connectionVarName -Value $connectionNameExpr -Force

            # Point workflow connectors to managed APIs in target subscription/location.
            $conn.id = "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/$apiName')]"
            # Point to placeholder Microsoft.Web/connections resources that this template will create.
            $conn.connectionName = "[variables('$connectionVarName')]"
            $conn.connectionId = "[resourceId('Microsoft.Web/connections', variables('$connectionVarName'))]"
            $connectionsToAdd.Add([pscustomobject]@{ apiName = $apiName; varName = $connectionVarName }) | Out-Null

            if ($conn.PSObject.Properties['connectionProperties']) {
                $conn.PSObject.Properties.Remove('connectionProperties')
                $findings.Add("- Removed connectionProperties from '$($connProp.Name)'") | Out-Null
            }

            $findings.Add("- Normalized connector '$($connProp.Name)' to dynamic connection variable '$connectionVarName'") | Out-Null
        }

        # Apply alias normalization in $connections and update all workflow action references.
        foreach ($u in @($aliasUpdates | Sort-Object old -Unique)) {
            $connValue = $resource.properties.parameters.'$connections'.value
            if ($connValue.PSObject.Properties[$u.old]) {
                if (-not $connValue.PSObject.Properties[$u.new]) {
                    $connValue | Add-Member -MemberType NoteProperty -Name $u.new -Value $connValue.PSObject.Properties[$u.old].Value -Force
                }
                $connValue.PSObject.Properties.Remove($u.old)
                $findings.Add("- Renamed workflow connection alias '$($u.old)' to '$($u.new)'") | Out-Null
            }

            # Action references are normalized in final serialized JSON replacement.
        }

        # Create Microsoft.Web/connections stub resources (Sentinel MCAS sample pattern).
        # These are placeholder connections that the user authorizes post-deploy via the Logic App designer.
        $dependsOnList = [System.Collections.Generic.List[string]]::new()
        foreach ($connToAdd in $connectionsToAdd) {
            $connResource = [pscustomobject][ordered]@{
                type = 'Microsoft.Web/connections'
                apiVersion = '2016-06-01'
                name = "[variables('$($connToAdd.varName)')]"
                location = '[resourceGroup().location]'
                properties = [pscustomobject][ordered]@{
                    displayName = "[concat('PLACEHOLDER-DELETE-AFTER-DEPLOY-', '$($connToAdd.apiName)')]"
                    customParameterValues = [pscustomobject]@{}
                    api = [pscustomobject][ordered]@{
                        id = "[concat('/subscriptions/', subscription().subscriptionId, '/providers/Microsoft.Web/locations/', resourceGroup().location, '/managedApis/$($connToAdd.apiName)')]"
                    }
                }
            }
            $template.resources = @($template.resources) + @($connResource)
            $dependsOnList.Add("[resourceId('Microsoft.Web/connections', variables('$($connToAdd.varName)'))]") | Out-Null
            $findings.Add("- Added Microsoft.Web/connections stub resource for '$($connToAdd.apiName)'") | Out-Null
            $findings.Add("- Labeled '$($connToAdd.apiName)' connection as PLACEHOLDER-DELETE-AFTER-DEPLOY-* in displayName") | Out-Null
        }

        if ($dependsOnList.Count -gt 0) {
            $resource | Add-Member -MemberType NoteProperty -Name dependsOn -Value @($dependsOnList) -Force
            $findings.Add("- Added workflow dependsOn for $($dependsOnList.Count) connection stub(s)") | Out-Null
        }

        $findings.Add("- Connection stubs require post-deploy authorization in the Logic App designer") | Out-Null
    }
}

Write-Step "Writing sanitized template"
$sanitizedPath = "template.sanitized.json"
$sanitizedJson = $template | ConvertTo-Json -Depth 100
$sanitizedJson = $sanitizedJson.Replace("@parameters('$connections')['azuremonitorlogs-1']", "@parameters('$connections')['azuremonitorlogs']")
$sanitizedJson = $sanitizedJson.Replace("['azuremonitorlogs-1']['connectionId']", "['azuremonitorlogs']['connectionId']")
$sanitizedJson | Out-File -FilePath $sanitizedPath -Encoding utf8
Write-Ok "Sanitized template written"

Write-Step "Writing parameters file"
$paramsBody = [ordered]@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = [ordered]@{
        logicAppName = [ordered]@{ value = '' }
        workspaceName = [ordered]@{ value = $workspaceNameDefault }
        foundryUri = [ordered]@{ value = $foundryUriDefault }
    }
}

$parametersPath = "template.parameters.json"
$paramsBody | ConvertTo-Json -Depth 20 | Out-File -FilePath $parametersPath -Encoding utf8
Write-Ok "Parameters file written"

Write-Step "Writing sanitize report"
$reportPath = "sanitize-report.md"
$reportLines = @(
    "# Sanitization Report",
    "Version: $ScriptVersion",
    "",
    "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss K')",
    "",
    "## Files",
    "- Original template: template.json",
    "- Sanitized template: $sanitizedPath",
    "- Parameters file: $parametersPath",
    "",
    "## Changes Applied"
)

if ($findings.Count -eq 0) {
    $reportLines += "- No changes were required"
} else {
    $reportLines += $findings
}

$reportLines += ""
$reportLines += "## Required Inputs Before Deployment"
$reportLines += "- workspaceName"
$reportLines += "- foundryUri (default placeholder is intentionally non-functional)"
$reportLines += ""
$reportLines += "## Notes"
$reportLines += "- Microsoft.Web/connections stub resources are deployed alongside the workflow (Sentinel MCAS sample pattern)."
$reportLines += "- After deployment, open the Logic App designer and authorize each connection (Sentinel and Azure Monitor Logs)."
$reportLines += "- No source-environment Foundry URI is retained in output defaults."

$reportLines | Out-File -FilePath $reportPath -Encoding utf8
Write-Ok "Report written"

Write-Host "`nCompleted" -ForegroundColor Cyan
Write-Host "1) Fill required values in template.parameters.json"
Write-Host "2) Validate: az deployment group what-if --resource-group <target-rg> --template-file template.sanitized.json --parameters @template.parameters.json"
