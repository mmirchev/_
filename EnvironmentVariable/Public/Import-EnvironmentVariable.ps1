function Import-EnvironmentVariable {
    <#
    .SYNOPSIS
        Imports environment variables from a JSON export into the Machine, User and/or Process scope.

    .DESCRIPTION
        Reads a JSON file produced by an environment-variable export (an object with
        "Machine", "User" and/or "Process" properties, each holding name/value pairs) and
        applies the variables to the corresponding scope. Scopes without a matching
        section in the file are skipped.

        By default, variables that already exist in the target scope are skipped and a
        warning is emitted. Use -Force to overwrite existing values.

        Emits one result object per variable (Name, Scope, Status) so the outcome can be
        filtered or logged through the pipeline. Supports -WhatIf and -Confirm.

        Writing to the Machine scope requires an elevated (administrator) session.
        Process-scope variables apply to the current process only (this session and any
        child processes it starts); they are not persisted.

    .PARAMETER Path
        Path to the JSON file containing the exported variables.
        Defaults to .\EnvironmentVariables.json. Accepts pipeline input, e.g. from Get-Item.

    .PARAMETER Scope
        One or more scopes to import: Machine, User, Process
        ([System.EnvironmentVariableTarget] values). Defaults to all three.

    .PARAMETER Force
        Overwrite variables that already exist in the target scope instead of skipping them.

    .EXAMPLE
        PS> Import-EnvironmentVariable

        Imports every scope section found in .\EnvironmentVariables.json, skipping
        variables that already exist.

    .EXAMPLE
        PS> Import-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json -Force

        Imports the given file and overwrites variables that already exist.

    .EXAMPLE
        PS> Import-EnvironmentVariable -Scope User -WhatIf

        Shows which User-scope variables would be set without changing anything.

    .EXAMPLE
        PS> Import-EnvironmentVariable -Scope Process -Force

        Re-applies the exported Process section to the current session, overwriting
        variables that are already set.

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
        [System.EnvironmentVariableTarget[]]$Scope = @(
            [System.EnvironmentVariableTarget]::Machine,
            [System.EnvironmentVariableTarget]::User,
            [System.EnvironmentVariableTarget]::Process
        ),

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

        foreach ($currentScope in $Scope | Select-Object -Unique) {
            $scopeName = $currentScope.ToString()
            $variables = $envData.$scopeName

            if ($null -eq $variables) {
                Write-Verbose "No '$scopeName' section found in '$Path'; skipping scope."
                continue
            }

            Write-Verbose "Processing $scopeName variables..."

            foreach ($property in $variables.psobject.Properties) {
                $name = $property.Name
                $value = [string]$property.Value

                $existingValue = [System.Environment]::GetEnvironmentVariable($name, $currentScope)

                if ($null -ne $existingValue -and -not $Force) {
                    Write-Warning "Skipped [$scopeName]: $name (already exists; use -Force to overwrite)"
                    [pscustomobject]@{ Name = $name; Scope = $scopeName; Status = 'Skipped' }
                    continue
                }

                $status = if ($null -eq $existingValue) { 'Imported' } else { 'Overwritten' }

                if ($PSCmdlet.ShouldProcess("$name ($scopeName scope)", 'Set environment variable')) {
                    try {
                        [System.Environment]::SetEnvironmentVariable($name, $value, $currentScope)
                        Write-Verbose "$status [$scopeName]: $name"
                        [pscustomobject]@{ Name = $name; Scope = $scopeName; Status = $status }
                    }
                    catch {
                        Write-Error "Failed to set [$scopeName]: $name — $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}
