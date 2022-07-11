function Get-AtomParamValue {

    [Alias("ampget")]
    Param(
        [Parameter(Position = 0)]
        $Scope,
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $AtomKey
    )

    $paramValue
    if ($Scope) {
        $paramValue = Invoke-AtomExtensionModule `
            -Type "Params.Scopes" -Name $Scope `
            -FunctionName:"Get-AtomScopedParamValue" `
            -FunctionArgs @{ AtomKey = $AtomKey }
    }
    else {
        $scopeOrder = @("File", "Session", "Invoke")
        $scopeOrder | ForEach-Object {
            $scopeValue = Invoke-AtomExtensionModule `
                -Type "Params.Scopes" -Name $_ `
                -FunctionName:"Get-AtomScopedParamValue" `
                -FunctionArgs @{ AtomKey = $AtomKey }
            if ($scopeValue) {
                $paramValue = $scopeValue
            }
        }
    }

    return $paramValue
}


function Set-AtomParamValue {

    [Alias("atomset")]
    Param(
        
        [Parameter(ValueFromPipeline = $true)]
        $AtomKey,
        [Parameter(Position = 0)]
        $Scope,
        [Parameter(Position = 1)]
        $Value,
        [Switch]
        [Parameter(Position = 2)]
        $Secret
    )
    $preparedValue = $Value
    if ($Secret) {
        $preparedValue = ( ConvertTo-SecureString $preparedValue  -AsPlainText)
    }

    Invoke-AtomExtensionModule `
        -Type "Params.Scopes" -Name $Scope `
        -FunctionName:"Set-AtomScopedParamValue" `
        -FunctionArgs @{
        AtomKey = $AtomKey 
        Value   = $preparedValue
    }
}

