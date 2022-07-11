
function Find-CasaCommand {
    Param(
        $Command = "",
        $Module = "*Casa*"
    )
    return (Get-Module $Module ).ExportedCommands.Values | where-object { $_.Name -like "*$Command*" }
}


