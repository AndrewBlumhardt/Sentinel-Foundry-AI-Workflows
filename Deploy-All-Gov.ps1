#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys all Sentinel Foundry AI playbooks to an Azure Government resource group.

.DESCRIPTION
    Downloads and runs locally. Iterates every playbook folder under ./playbooks/ and
    deploys its azuredeploy.json using the Azure CLI targeting the AzureUSGovernment cloud.
    Prompts for required values if not supplied as parameters.

    Prerequisites:
      - Azure CLI installed and signed in to AzureUSGovernment:
          az cloud set --name AzureUSGovernment
          az login
      - PowerShell 7+
      - Contributor (or equivalent) rights on the target resource group

.EXAMPLE
    .\Deploy-All-Gov.ps1 -ResourceGroup MyRG -WorkspaceName my-sentinel-ws -FoundryUri https://my-foundry.openai.azure.us/openai/deployments/gpt-4o/chat/completions?api-version=2025-01-01-preview

.EXAMPLE
    .\Deploy-All-Gov.ps1  # prompts for all required values interactively
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup,

    [Parameter(Mandatory = $false)]
    [string]$WorkspaceName,

    [Parameter(Mandatory = $false)]
    [string]$FoundryUri,

    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

# Verify CLI is targeting Azure Government
$currentCloud = (az cloud show --query name -o tsv 2>$null)
if ($currentCloud -ne 'AzureUSGovernment') {
    Write-Host "WARNING: Azure CLI is currently set to '$currentCloud', not AzureUSGovernment." -ForegroundColor Yellow
    Write-Host "Switch with: az cloud set --name AzureUSGovernment && az login" -ForegroundColor Yellow
    $confirm = Read-Host "Continue anyway? (y/N)"
    if ($confirm -ne 'y') { exit 0 }
}

if (-not $ResourceGroup)  { $ResourceGroup  = Read-Host "Resource group name" }
if (-not $WorkspaceName)  { $WorkspaceName  = Read-Host "Log Analytics workspace name" }
if (-not $FoundryUri)     { $FoundryUri     = Read-Host "Foundry endpoint URI" }

$playbooksRoot = Join-Path $PSScriptRoot 'playbooks'
if (-not (Test-Path $playbooksRoot)) {
    throw "playbooks/ folder not found next to this script. Run from the repo root."
}

$playbooks = Get-ChildItem -Path $playbooksRoot -Directory | Sort-Object Name

Write-Host "`nDeploying $($playbooks.Count) playbooks to resource group: $ResourceGroup (Azure Government)" -ForegroundColor Cyan

$results = [System.Collections.Generic.List[pscustomobject]]::new()

foreach ($pb in $playbooks) {
    $template = Join-Path $pb.FullName 'azuredeploy.json'
    if (-not (Test-Path $template)) {
        Write-Host "[SKIP] $($pb.Name) - azuredeploy.json not found" -ForegroundColor Yellow
        $results.Add([pscustomobject]@{ Playbook = $pb.Name; Status = 'Skipped' })
        continue
    }

    $timestamp   = Get-Date -Format 'yyyyMMddHHmmss'
    $safeName    = $pb.Name -replace '[^A-Za-z0-9-]', '-'
    $deployName  = "$safeName-$timestamp"
    $logicName   = $pb.Name -replace '_', '-'

    Write-Host "`n[DEPLOY] $($pb.Name)" -ForegroundColor Cyan

    $azArgs = @(
        'deployment', 'group', 'create',
        '--resource-group', $ResourceGroup,
        '--name', $deployName,
        '--template-file', $template,
        '--parameters',
            "logicAppName=$logicName",
            "workspaceName=$WorkspaceName",
            "foundryUri=$FoundryUri"
    )

    if ($WhatIf) { $azArgs += '--what-if' }

    $exitCode = 0
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
