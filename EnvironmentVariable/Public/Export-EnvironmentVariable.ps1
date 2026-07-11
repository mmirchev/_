function Export-EnvironmentVariable {
    <#
    .SYNOPSIS
        Exports environment variables from the Machine, User and/or Process scope to a JSON file.

    .DESCRIPTION
        Collects the environment variables of the requested scopes and writes them to a
        JSON file as an object with one section per scope (e.g. "Machine", "User",
        "Process"), each holding name/value pairs. Variable names are sorted within each
        section so repeated exports diff cleanly.

        The output format is the one consumed by Import-EnvironmentVariable (which applies
        the "Machine" and "User" sections; a "Process" section is exported for reference
        but is not imported, since process-scope variables die with the process).

        Returns the FileInfo of the written file, so the result can be piped straight into
        Import-EnvironmentVariable. Supports -WhatIf and -Confirm. An existing file at the
        target path is overwritten.

    .PARAMETER Path
        Path of the JSON file to write. Defaults to .\EnvironmentVariables.json.

    .PARAMETER Scope
        One or more scopes to export: Machine, User, Process
        ([System.EnvironmentVariableTarget] values). Defaults to all three.

    .EXAMPLE
        PS> Export-EnvironmentVariable

        Exports Machine, User and Process variables to .\EnvironmentVariables.json.

    .EXAMPLE
        PS> Export-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json -Scope Machine, User

        Exports only the persistent scopes to the given file.

    .EXAMPLE
        PS> Export-EnvironmentVariable -Scope User | Import-EnvironmentVariable -Force

        Round-trips the User scope: exports it, then re-applies it, overwriting conflicts.

    .OUTPUTS
        [System.IO.FileInfo] for the written JSON file.

    .NOTES
        Dot-source this file to load the function:
            . .\Export-EnvironmentVariable.ps1
            Export-EnvironmentVariable -Scope Machine, User
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position = 0)]
        [Alias('OutputFile')]
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.\EnvironmentVariables.json',

        [Parameter()]
        [System.EnvironmentVariableTarget[]]$Scope = @(
            [System.EnvironmentVariableTarget]::Machine,
            [System.EnvironmentVariableTarget]::User,
            [System.EnvironmentVariableTarget]::Process
        )
    )

    $envData = [ordered]@{}

    foreach ($currentScope in $Scope | Select-Object -Unique) {
        $variables = [System.Environment]::GetEnvironmentVariables($currentScope)

        $section = [ordered]@{}
        foreach ($name in ($variables.Keys | Sort-Object)) {
            $section[$name] = [string]$variables[$name]
        }

        $envData[$currentScope.ToString()] = $section
        Write-Verbose "Collected $($section.Count) $currentScope variable(s)."
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Export environment variables')) {
        try {
            [pscustomobject]$envData |
                ConvertTo-Json -Depth 3 |
                Out-File -LiteralPath $Path -Encoding utf8 -ErrorAction Stop
        }
        catch {
            throw "Failed to write '$Path': $($_.Exception.Message)"
        }

        Write-Verbose "Environment variables exported to '$Path'."
        Get-Item -LiteralPath $Path
    }
}
