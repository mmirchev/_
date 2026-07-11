# EnvironmentVariable

PowerShell module for backing up and restoring environment variables via JSON.

| Command | Purpose |
| --- | --- |
| `Export-EnvironmentVariable` | Export Machine/User/Process variables to a JSON file (default: all three scopes). |
| `Import-EnvironmentVariable` | Apply Machine/User/Process variables from a JSON export (default: all sections present); skips existing variables unless `-Force` is given. |

## Install

```powershell
git clone https://github.com/mmirchev/_.git
cd _
.\install.ps1
```

This copies the module into your user-scope module directory and imports it. Works in Windows PowerShell 5.1 and PowerShell 7+.

## Usage

```powershell
# Back up the persistent scopes
Export-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json -Scope Machine, User

# Restore, keeping existing variables
Import-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json

# Restore, overwriting conflicts (Machine scope needs an elevated session)
Import-EnvironmentVariable -Path C:\Backup\EnvironmentVariables.json -Force

# Re-apply the exported Process section to the current session only
Import-EnvironmentVariable -Scope Process -Force

# Preview without changing anything
Import-EnvironmentVariable -Force -WhatIf
```

Machine/User imports persist; Process imports affect only the current session and its child processes.

Both commands support `-WhatIf`/`-Confirm` and have full help: `Get-Help Import-EnvironmentVariable -Full`.
