# Introduction
Casa is a PowerShell library for managing PowerShell modules sessions. The goals of this project are as follows:
1) Simplify organizing, finding and executing PowerShell commands without requiring any special syntax or libraries 
2) Securely store command parameters and input them automatically when invoked later
3) Make unattended execution easier 

# Concepts 
- **Zones** represent an isolated set of PS modules and Casa resources.
- **Personas** are configuration files that state which zones/modules are required. Personas can also specify any Params values
- **Params** store and reuse the parameter values passed-in when invoking PowerShell commands with Casa

# Getting Started

```Powershell
# Casa.ps1 simplifies a lot of the startup - Supply a persona file
C:\Code\Casa\Casa.ps1 -PersonaFile C:\Code\Casa-mho\home.yaml

# Get the available parameters for a loaded command
Get-Command Find-AirtableRecord | Get-CasaCommandParams
#output below
# Name                           Value
# ----                           -----
# Table                          @{Name=Table; DefaultValue=; Mandatory=True}
# View                           @{Name=View; DefaultValue=; Mandatory=False}
# ApiKey                         @{Name=ApiKey; DefaultValue=; Mandatory=False}
# BaseId                         @{Name=BaseId; DefaultValue=; Mandatory=True}
# FilterFormula                  @{Name=FilterFormula; DefaultValue=; Mandatory=False}

# Set Params in session (Cleared when PowerShell is restarted)
# Note: '-ParamName View' is added to add 
gcm Find-AirtableRecord | Get-CasaCommandKey -ParamName View | Set-CasaParamValue -Scope Session -Value "Master"
gcm Find-AirtableRecord | Get-CasaCommandKey -ParamName View | Get-CasaParamValue -Scope Session
#output below
Master

#Save Params to the filesystem (shortened with alianses)
gcm Find-AirtableRecord | ampkey View | paramset File "Grid view"
gcm Find-AirtableRecord | ampkey View | paramget File "Grid view"
#output below
gcm Find-AirtableRecord | ampkey View | paramset File "Grid view"
```



# Features

## Params
Params are the concept that stores and reuses the parameter values used when invoking a PowerShell Command 

| Feature                                           | Progress | Notes |
| ------------------------------------------------- | -------- | ----- |
| Params can be stored in session                   | 100%     |       |
| Params can be stored in files                     | 100%     |       |
| Use stored Params when invoking a command in Casa | 50%     |       |
| Automatically clone zones from git repos          | todo     |       |

# Other Tasks

- [x] Rename circuits to zones ✅ 2022-04-15
- [ ] When modules folder doesn't exist, `Start-Casa` should skip instead of throwing error
- [ ] Casa build scripts (Take from CASA)
- [ ] Restart session and reload modules completely