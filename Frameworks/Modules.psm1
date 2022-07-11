
function Find-AtomCommand {
    Param(
        $Command = "",
        $Module = "*Atom*"
    )
    return (Get-Module $Module ).ExportedCommands.Values | where-object { $_.Name -like "*$Command*" }
}


