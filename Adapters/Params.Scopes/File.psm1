function Get-AtomScopedParamValue {
    Param(
        $AtomKey
    )
    
    
    $valuePath = "C:\Code\_Atom_values"
    $keyRelPath = $AtomKey -replace " ","\"
    $valuePathFinal = $valuePath | Join-Path -ChildPath $keyRelPath
    $valueFilePath = $valuePathFinal | Join-Path -ChildPath "value.xml"

    if(Test-Path $valueFilePath)
    {
        Import-Clixml -Path $valueFilePath
    }
}

function Set-AtomScopedParamValue {
    Param(
        $AtomKey,
        $Value
    )
    $valuePath = "C:\Code\_Atom_values"
    $keyRelPath = $AtomKey -replace " ","\"
    
    $valuePathFinal = $valuePath | Join-Path -ChildPath $keyRelPath
    New-Item $valuePathFinal -ItemType Directory -Force

    $valueFilePath = $valuePathFinal | Join-Path -ChildPath "value.xml"

    Export-Clixml -InputObject $Value -Path $valueFilePath
    

}