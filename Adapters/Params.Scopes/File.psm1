function Get-CasaScopedParamValue {
    Param(
        $CasaKey
    )
    
    
    $valuePath = "C:\Code\_Casa_values"
    $keyRelPath = $CasaKey -replace " ","\"
    $valuePathFinal = $valuePath | Join-Path -ChildPath $keyRelPath
    $valueFilePath = $valuePathFinal | Join-Path -ChildPath "value.xml"

    if(Test-Path $valueFilePath)
    {
        Import-Clixml -Path $valueFilePath
    }
}

function Set-CasaScopedParamValue {
    Param(
        $CasaKey,
        $Value
    )
    $valuePath = "C:\Code\_Casa_values"
    $keyRelPath = $CasaKey -replace " ","\"
    
    $valuePathFinal = $valuePath | Join-Path -ChildPath $keyRelPath
    New-Item $valuePathFinal -ItemType Directory -Force

    $valueFilePath = $valuePathFinal | Join-Path -ChildPath "value.xml"

    Export-Clixml -InputObject $Value -Path $valueFilePath
    

}