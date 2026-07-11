@{
    RootModule           = 'EnvironmentVariable.psm1'
    ModuleVersion        = '1.1.0'
    GUID                 = 'e6e54176-6803-4fe2-bdf7-cee4a8f4c63c'
    Author               = 'Mihail Mirchev'
    Copyright            = '(c) 2026 Mihail Mirchev. All rights reserved.'
    Description          = 'Export and import environment variables (Machine/User/Process scope) to and from JSON, with -Force overwrite and -WhatIf support.'
    PowerShellVersion    = '5.1'
    CompatiblePSEditions = @('Desktop', 'Core')
    FunctionsToExport    = @('Export-EnvironmentVariable', 'Import-EnvironmentVariable')
    CmdletsToExport      = @()
    VariablesToExport    = @()
    AliasesToExport      = @()
    PrivateData          = @{
        PSData = @{
            Tags       = @('Environment', 'EnvironmentVariables', 'Backup', 'Windows')
            ProjectUri = 'https://github.com/mmirchev/_'
        }
    }
}
