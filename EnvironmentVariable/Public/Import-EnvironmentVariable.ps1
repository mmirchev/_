function Import-EnvironmentVariable {
    <#
    .SYNOPSIS
        Imports environment variables from a JSON export into the Machine and/or User scope.

    .DESCRIPTION
        Reads a JSON file produced by an environment-variable export (an object with
        "Machine" and "User" properties, each holding name/value pairs) and applies the
        variables to the corresponding scope.

        By default, variables that already exist in the target scope are skipped and a
        warning is emitted. Use -Force to overwrite existing values.

        Emits one result object per variable (Name, Scope, Status) so the outcome can be
        filtered or logged through the pipeline. Supports -WhatIf and -Confirm.

        Writing to the Machine scope requires an elevated (administrator) session.

    .PARAMETER Path
        Path to the JSON file containing the exported variables.
        Defaults to .\EnvironmentVariables.json. Accepts pipeline input, e.g. from Get-Item.

    .PARAMETER Scope
        One or more scopes to import: 'Machine', 'User'. Defaults to both.

    .PARAMETER Force
        Overwrite variables that already exist in the target scope instead of skipping them.

    .EXAMPLE
        PS> Import-EnvironmentVariable

        Imports .\EnvironmentVariables.json into both scopes, skipping variables that
        already exist.

    .EXAMPLE
        PS> Import-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json -Force

        Imports the given file and overwrites variables that already exist.

    .EXAMPLE
        PS> Import-EnvironmentVariable -Scope User -WhatIf

        Shows which User-scope variables would be set without changing anything.

    .OUTPUTS
        [pscustomobject] with Name, Scope and Status ('Imported', 'Overwritten' or 'Skipped').

    .NOTES
        Dot-source this file to load the function:
            . .\Import-EnvironmentVariable.ps1
            Import-EnvironmentVariable -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputFile', 'FullName')]
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.\EnvironmentVariables.json',

        [Parameter()]
        [ValidateSet('Machine', 'User')]
        [string[]]$Scope = @('Machine', 'User'),

        [Parameter()]
        [switch]$Force
    )

    process {
        if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
            throw "Input file not found: '$Path'. Ensure the variables were exported first."
        }

        try {
            $envData = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            throw "Failed to read or parse '$Path' as JSON: $($_.Exception.Message)"
        }

        foreach ($currentScope in $Scope) {
            $target = [System.EnvironmentVariableTarget]$currentScope
            $variables = $envData.$currentScope

            if ($null -eq $variables) {
                Write-Verbose "No '$currentScope' section found in '$Path'; skipping scope."
                continue
            }

            Write-Verbose "Processing $currentScope variables..."

            foreach ($property in $variables.psobject.Properties) {
                $name = $property.Name
                $value = [string]$property.Value

                $existingValue = [System.Environment]::GetEnvironmentVariable($name, $target)

                if ($null -ne $existingValue -and -not $Force) {
                    Write-Warning "Skipped [$currentScope]: $name (already exists; use -Force to overwrite)"
                    [pscustomobject]@{ Name = $name; Scope = $currentScope; Status = 'Skipped' }
                    continue
                }

                $status = if ($null -eq $existingValue) { 'Imported' } else { 'Overwritten' }

                if ($PSCmdlet.ShouldProcess("$name ($currentScope scope)", 'Set environment variable')) {
                    try {
                        [System.Environment]::SetEnvironmentVariable($name, $value, $target)
                        Write-Verbose "$status [$currentScope]: $name"
                        [pscustomobject]@{ Name = $name; Scope = $currentScope; Status = $status }
                    }
                    catch {
                        Write-Error "Failed to set [$currentScope]: $name — $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
