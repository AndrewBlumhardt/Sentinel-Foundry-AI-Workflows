param(
    [Parameter(Mandatory = $true)]
    [string]$WorkflowFolder,

    [Parameter(Mandatory = $true)]
    [string]$ResourceGroup,

    [string]$DeploymentName,

    [string[]]$Parameters,

    [switch]$WhatIf
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$templateFile = Join-Path $PSScriptRoot $WorkflowFolder
$templateFile = Join-Path $templateFile 'template.json'

if (-not (Test-Path $templateFile)) {
    throw "Template not found: $templateFile"
}

if (-not $DeploymentName) {
    $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
    $safeName = $WorkflowFolder -replace '[^A-Za-z0-9-]', '-'
    $DeploymentName = "$safeName-$timestamp"
}

$azArgs = @(
    'deployment', 'group', 'create',
    '--resource-group', $ResourceGroup,
    '--name', $DeploymentName,
    '--template-file', $templateFile
)

if ($WhatIf) {
    $azArgs += '--what-if'
}

if ($Parameters) {
    $azArgs += '--parameters'
    $azArgs += $Parameters
}

Write-Host "Deploying $WorkflowFolder to resource group $ResourceGroup"
& az @azArgs