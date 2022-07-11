function Get-CasaParamValue {

    [Alias("ampget")]
    Param(
        [Parameter(Position = 0)]
        $Scope,
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        $CasaKey
    )

    $paramValue
    if ($Scope) {
        $paramValue = Invoke-CasaExtensionModule `
            -Type "Params.Scopes" -Name $Scope `
            -FunctionName:"Get-CasaScopedParamValue" `
            -FunctionArgs @{ CasaKey = $CasaKey }
    }
    else {
        $scopeOrder = @("File", "Session", "Invoke")
        $scopeOrder | ForEach-Object {
            $scopeValue = Invoke-CasaExtensionModule `
                -Type "Params.Scopes" -Name $_ `
                -FunctionName:"Get-CasaScopedParamValue" `
                -FunctionArgs @{ CasaKey = $CasaKey }
            if ($scopeValue) {
                $paramValue = $scopeValue
            }
        }
    }

    return $paramValue
}


function Set-CasaParamValue {

    [Alias("casaset")]
    Param(
        
        [Parameter(ValueFromPipeline = $true)]
        $CasaKey,
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

    Invoke-CasaExtensionModule `
        -Type "Params.Scopes" -Name $Scope `
        -FunctionName:"Set-CasaScopedParamValue" `
        -FunctionArgs @{
        CasaKey = $CasaKey 
        Value   = $preparedValue
    }
}

