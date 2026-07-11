<#
.SYNOPSIS
    Installs the EnvironmentVariable module into your user-scope PowerShell module path.

.DESCRIPTION
    Copies the EnvironmentVariable module folder from this repository into the first
    (user-scope) directory of $env:PSModulePath, replacing any previously installed
    copy, then imports it and lists the exported commands.

    Run from the repository root:
        .\install.ps1

    Works in both Windows PowerShell 5.1 and PowerShell 7+. Supports -WhatIf.

.EXAMPLE
    PS> .\install.ps1

    Installs the module for the current user and imports it.
#>
[CmdletBinding(SupportsShouldProcess)]
param ()

$moduleName = 'EnvironmentVariable'
$source = Join-Path $PSScriptRoot $moduleName

if (-not (Test-Path -LiteralPath (Join-Path $source "$moduleName.psd1"))) {
    throw "Module source not found at '$source'. Run this script from the repository root."
}

# First PSModulePath entry is the current user's module directory by convention
$userModuleRoot = ($env:PSModulePath -split [System.IO.Path]::PathSeparator)[0]
$destination = Join-Path $userModuleRoot $moduleName

if ($PSCmdlet.ShouldProcess($destination, "Install module '$moduleName'")) {
    if (-not (Test-Path -LiteralPath $userModuleRoot)) {
        New-Item -Path $userModuleRoot -ItemType Directory -Force | Out-Null
    }
    if (Test-Path -LiteralPath $destination) {
        Remove-Item -LiteralPath $destination -Recurse -Force
    }
    Copy-Item -LiteralPath $source -Destination $destination -Recurse

    Import-Module $moduleName -Force
    Write-Host "Installed '$moduleName' to $destination" -ForegroundColor Green
    Get-Command -Module $moduleName
}
