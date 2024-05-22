# Introduction
Atom is a PowerShell library for managing PowerShell modules and sessions. The goals of this project are as follows:
1) Simplify organizing, finding and executing PowerShell commands without requiring any special syntax or libraries 
2) Securely store command parameters and input them automatically when invoked later
3) Make unattended execution easier 

# Concepts 
- **Zones** represent an isolated set of PS modules and Atom resources.
- **Personas** are configuration files that state which zones/modules are required. Personas can also specify any Params values
- **Params** store and reuse the parameter values passed-in when invoking PowerShell commands with Atom

# Getting Started

## Prerequisites

The core Atom framework doesn't rely on any other software to be installed. However, `git` is likely the easiest way to manage your Atom Zones. This can be done many ways but opening the following in a ClickOnce capable web-browser will quickly install any software needed.

 **Easy up-to-date link to install any required software:**

`https://boxstarter.org/package/nr/git`

## Clone the framework and any zones
```Powershell

#Clone the core Atom framework
git clone git@github.com:armunro/atom-core.git
Set-Location Zones

#Clone the public zone repo
git submodule add git@github.com:armunro/atom-public.git

#Clone my private repo for home stuff
git submodule add git@github.com:armunro/atom-munro-private.git
```

## Create a Persona file
Persona files are YAML config files that let you configure your expected PowerShell session state when Atom launches the persona.

```yaml
name: "home"
description: "Modules for typical home use including MHO modules"
zones:
  - name: public
    color: green
    path: C:\Atom\atom-public
    modules:
      - "*Bitwarden*"
      - "*Airtable*"
  - name: munro
    color: red
    path: C:\Atom\atom-munro
    modules:
      - "AM.Projects.VCS*"
    packages:
      - provider: choco
        package: obsidian
      - provider: choco
        package: bitwarden
      - provider: PowerShellGet
        package: JiraPS
      - provider: PowerShellGet
        package: Microsoft.Graph
startupCommands:
  - name: "Greeting"
    command: 'Write-Host -ForegroundColor Magenta "Have a great day"'
    prompt: false
```

## Launch an Atom Persona 
Atom is fairly modular and can be initiated in smaller, more efficient configurations. However, for most people, the `Atom.ps1` script will provide the easiest startup.
```PowerShell
C:\Atom\atom-core\Atom.ps1 -PersonaFile C:\Code\atom-munro\home.yaml
```
```Powershell
# Get the available parameters for a loaded command
Get-Command Find-AirtableRecord | Get-AtomCommandParams
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
gcm Find-AirtableRecord | Get-AtomCommandKey -ParamName View | Set-AtomParamValue -Scope Session -Value "Master"
gcm Find-AirtableRecord | Get-AtomCommandKey -ParamName View | Get-AtomParamValue -Scope Session
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
| Use stored Params when invoking a command in Atom | 50%     |       |
| Automatically clone zones from git repos          | todo     |       |

# Other Tasks

- [x] Rename circuits to zones ✅ 2022-04-15
- [ ] When modules folder doesn't exist, `Start-Atom` should skip instead of throwing error
- [ ] Atom build scripts (Take from Atom)
- [ ] Restart session and reload modules completely