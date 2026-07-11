# Load the public functions shipped under Public/
foreach ($script in Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public') -Filter '*.ps1' -File) {
    . $script.FullName
}

Export-ModuleMember -Function 'Export-EnvironmentVariable', 'Import-EnvironmentVariable'
