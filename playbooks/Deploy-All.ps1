#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys all Sentinel Foundry AI playbooks to an Azure commercial resource group.

.DESCRIPTION
    Deploys the repository playbook templates from GitHub using Azure CLI
    template-uri. Prompts for required values if not supplied as parameters.

    Prerequisites:
      - Azure CLI installed and signed in: az login
      - PowerShell 7+
      - Contributor (or equivalent) rights on the target resource group

.EXAMPLE
    .\Deploy-All.ps1 -ResourceGroup MyRG -WorkspaceName my-sentinel-ws -FoundryUri https://my-foundry.openai.azure.com/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview

.EXAMPLE
    .\Deploy-All.ps1  # prompts for all required values interactively
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$FoundryUri,

    [Parameter(Mandatory = $false)]
    [string]$Subscription
)

$ErrorActionPreference = 'Stop'

$repoOwner = 'AndrewBlumhardt'
$repoName = 'Sentinel-Foundry-AI-Workflows'
$repoBranch = 'main'
$playbookNames = @(
    'close_low_risk_fp_using_foundry_ai',
    'entity_research_using_foundry_ai',
    'get_incident_tasks_from_foundry_ai',
    'get_kql_from_foundry_ai',
    'get_recovery_steps_from_foundry_ai',
    'prioritize_incident_using_foundry_ai',
    'send_foundry_ai_generated_email_summary',
    'send_incident_to_foundry_ai',
    'use_foundry_ai_to_evaluate_pim'
)

if (-not $ResourceGroup)  { $ResourceGroup  = Read-Host "Resource group name" }
if (-not $WorkspaceName)  { $WorkspaceName  = Read-Host "Log Analytics workspace name" }
if (-not $FoundryUri)     { $FoundryUri     = Read-Host "Foundry endpoint URI" }
if (-not $Subscription)   { $Subscription   = Read-Host "Subscription name or ID (leave blank for current default)" }

# Preflight: validate Azure CLI login and subscription context.
$null = az --version 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Azure CLI is not available. Install Azure CLI and rerun."
}

$currentCloud = (az cloud show --query name -o tsv 2>$null)
if ($currentCloud -ne 'AzureCloud') {
    Write-Host "NOTE: Azure CLI is currently set to '$currentCloud'. Switching to AzureCloud for commercial deployment." -ForegroundColor Yellow
    az cloud set --name AzureCloud
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to switch Azure CLI to AzureCloud."
    }
}

$accountJson = az account show -o json 2>$null
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accountJson)) {
    throw "Not logged in to Azure CLI. Run 'az login' and rerun the script."
}

if (-not [string]::IsNullOrWhiteSpace($Subscription)) {
    az account set --subscription $Subscription
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to select subscription '$Subscription'. Verify the name/ID and your access."
    }
    $accountJson = az account show -o json
}

$account = $accountJson | ConvertFrom-Json
Write-Host "Using Azure subscription: $($account.name) ($($account.id))" -ForegroundColor DarkCyan

$rgExists = az group exists --name $ResourceGroup -o tsv 2>$null
if ($LASTEXITCODE -ne 0) {
    throw "Unable to verify resource group '$ResourceGroup' in subscription $($account.id)."
}

if ($rgExists -ne 'true') {
    throw "Resource group '$ResourceGroup' was not found in subscription '$($account.name)' ($($account.id)). Select the correct subscription with -Subscription or create the resource group first."
}

$playbooks = $playbookNames | ForEach-Object { [pscustomobject]@{ Name = $_ } }

Write-Host "`nDeploying $($playbooks.Count) playbooks to resource group: $ResourceGroup" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($pb in $playbooks) {
    $templateUri = "https://raw.githubusercontent.com/$repoOwner/$repoName/$repoBranch/playbooks/$($pb.Name)/azuredeploy.json"

    $timestamp   = Get-Date -Format 'yyyyMMddHHmmss'
    $safeName    = $pb.Name -replace '[^A-Za-z0-9-]', '-'
    $deployName  = "$safeName-$timestamp"
    $logicName   = $pb.Name -replace '_', '-'

    Write-Host "`n[DEPLOY] $($pb.Name)" -ForegroundColor Cyan

    $azArgs = @(
        'deployment', 'group', 'create',
        '--resource-group', $ResourceGroup,
        '--name', $deployName,
        '--parameters',
            "logicAppName=$logicName",
            "workspaceName=$WorkspaceName",
            "foundryUri=$FoundryUri"
    )

    $azArgs += @('--template-uri', $templateUri)

    if ($WhatIfPreference) { $azArgs += '--what-if' }

    & az @azArgs
    $exitCode = $LASTEXITCODE

    $status = if ($exitCode -eq 0) { 'OK' } else { "Failed (exit $exitCode)" }
    $color  = if ($exitCode -eq 0) { 'Green' } else { 'Red' }
    Write-Host "[$status] $($pb.Name)" -ForegroundColor $color
    $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = $status })
}

Write-Host "`n--- Deployment Summary ---" -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = @($results | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'Skipped' })
if ($failed.Count -gt 0) {
    Write-Host "$($failed.Count) deployment(s) failed. Review the output above." -ForegroundColor Red
    exit 1
}
