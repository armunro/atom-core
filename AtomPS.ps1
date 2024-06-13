[CmdletBinding()]
Param (
    $PersonaFile,
    [Switch]
    $NoStartupCommands,
    $ZonePath
)

Import-Module powershell-yaml
Import-Module PSWriteColor

Get-Module -All | Where-Object {
    $_.Name.ToLower().StartsWith("atom") } 
| Remove-Module -Force

Import-Module $PSScriptRoot/AtomPS.psm1 -Force -DisableNameChecking
Import-AtomPersona $PersonaFile -ZonePath $ZonePath | Start-Atom -NoStartupCommands:$NoStartupCommands
