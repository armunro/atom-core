[CmdletBinding()]
Param (
    $PersonaFile,
    [Switch]
    $NoStartupCommands
)

Import-Module powershell-yaml
Import-Module PSWriteColor

Get-Module -All | Where-Object {
    $_.Name.ToLower().StartsWith("casa") } 
| Remove-Module -Force

Import-Module $PSScriptRoot/CasaPS.psm1 -Force -DisableNameChecking
Import-CasaPersona $PersonaFile | Start-Casa -NoStartupCommands:$NoStartupCommands
