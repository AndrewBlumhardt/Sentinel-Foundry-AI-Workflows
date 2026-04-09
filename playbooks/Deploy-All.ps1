#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys all Sentinel Foundry AI playbooks to an Azure commercial resource group.

.DESCRIPTION
    Iterates every playbook folder under the current directory and deploys its
    azuredeploy.json using the Azure CLI. Prompts for required values if not
    supplied as parameters.

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
    [string]$FoundryUri
)

$ErrorActionPreference = 'Stop'

if (-not $ResourceGroup)  { $ResourceGroup  = Read-Host "Resource group name" }
if (-not $WorkspaceName)  { $WorkspaceName  = Read-Host "Log Analytics workspace name" }
if (-not $FoundryUri)     { $FoundryUri     = Read-Host "Foundry endpoint URI" }

$playbooksRoot = $PSScriptRoot
$playbooks = Get-ChildItem -Path $playbooksRoot -Directory | Sort-Object Name

Write-Host "`nDeploying $($playbooks.Count) playbooks to resource group: $ResourceGroup" -ForegroundColor Cyan

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
